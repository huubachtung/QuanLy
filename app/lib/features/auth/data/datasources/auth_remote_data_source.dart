import 'dart:convert';
import '../models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> autoLogin();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRemoteDataSourceImpl({required this.apiClient, required this.tokenStorage});

  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final normalized = base64Url.normalize(parts[1]);
        final payload = utf8.decode(base64Url.decode(normalized));
        final map = jsonDecode(payload);
        if (map is Map) {
          return map['id']?.toString() ?? map['_id']?.toString() ?? map['userId']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel> _enrichUserWithDepartment(UserModel user) async {
    if (user.departmentId == null || (user.department != null && user.department!.isNotEmpty)) {
      return user;
    }
    try {
      final response = await apiClient.dio.get('/api/department/${user.departmentId}');
      final data = response.data;
      final deptData = data['data'] ?? data;
      final deptName = deptData['name']?.toString() ?? deptData['departmentName']?.toString();
      if (deptName != null && deptName.isNotEmpty) {
        return UserModel(
          id: user.id,
          username: user.username,
          displayName: user.displayName,
          email: user.email,
          phone: user.phone,
          avatar: user.avatar,
          employeeCode: user.employeeCode,
          role: user.role,
          employeeType: user.employeeType,
          department: deptName,
          departmentId: user.departmentId,
          hiredDate: user.hiredDate,
          annualLeaveBalance: user.annualLeaveBalance,
          baseSalary: user.baseSalary,
          workStartTime: user.workStartTime,
          workEndTime: user.workEndTime,
          leaveBalances: user.leaveBalances,
        );
      }
    } catch (_) {}
    return user;
  }

  Future<UserModel> _fetchFullUserProfile(String userId, UserModel fallback) async {
    try {
      final response = await apiClient.dio.get(ApiConstants.userProfile(userId));
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        var user = UserModel.fromJson(data['data']);
        if (user.department == null && user.departmentId != null) {
          user = await _enrichUserWithDepartment(user);
        }
        return user;
      }
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        var user = UserModel.fromJson(data['data']);
        if (user.department == null && user.departmentId != null) {
          user = await _enrichUserWithDepartment(user);
        }
        return user;
      }
    } catch (_) {}
    return fallback;
  }

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await apiClient.dio.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    final data = response.data;
    
    // Backend trả về: { accessToken, refreshToken, user } hoặc wrapper { success: true, data: { ... } }
    final token = data['accessToken'] ?? data['access_token'] ?? (data['data'] is Map ? data['data']['accessToken'] ?? data['data']['access_token'] : null);
    final refreshToken = data['refreshToken'] ?? data['refresh_token'] ?? (data['data'] is Map ? data['data']['refreshToken'] ?? data['data']['refresh_token'] : null);
    final userData = data['user'] ?? (data['data'] is Map ? data['data']['user'] ?? (data['data']['_id'] != null ? data['data'] : null) : null);
    
    if (token != null && userData != null) {
      var user = UserModel.fromJson(userData);
      final userId = user.id.isNotEmpty ? user.id : _getUserIdFromToken(token.toString()) ?? '';
      
      await tokenStorage.saveTokens(
        accessToken: token.toString(),
        refreshToken: refreshToken?.toString(),
        userId: userId,
      );

      if (userId.isNotEmpty) {
        user = await _fetchFullUserProfile(userId, user);
      }
      
      if (user.department == null && user.departmentId != null) {
        user = await _enrichUserWithDepartment(user);
      }
      
      await tokenStorage.saveUserData(user.toJson());
      
      return user;
    }
    
    throw ServerException(data['message'] ?? 'Đăng nhập thất bại');
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post(ApiConstants.logout);
    } catch (e) {
      // Bỏ qua lỗi mạng khi logout
    }
    await tokenStorage.clearAll();
  }

  @override
  Future<UserModel?> autoLogin() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null) return null;

    var userId = await tokenStorage.getUserId();
    if (userId == null || userId.isEmpty) {
      userId = _getUserIdFromToken(token);
      if (userId != null) {
        await tokenStorage.saveTokens(accessToken: token, userId: userId);
      }
    }
    if (userId == null) return null;

    try {
      final response = await apiClient.dio.get(ApiConstants.userProfile(userId));
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        var user = UserModel.fromJson(data['data']);
        if (user.department == null && user.departmentId != null) {
          user = await _enrichUserWithDepartment(user);
        }
        await tokenStorage.saveUserData(user.toJson());
        return user;
      }
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        var user = UserModel.fromJson(data['data']);
        if (user.department == null && user.departmentId != null) {
          user = await _enrichUserWithDepartment(user);
        }
        await tokenStorage.saveUserData(user.toJson());
        return user;
      }
      if (data is Map<String, dynamic> && data['username'] != null) {
        var user = UserModel.fromJson(data);
        if (user.department == null && user.departmentId != null) {
          user = await _enrichUserWithDepartment(user);
        }
        await tokenStorage.saveUserData(user.toJson());
        return user;
      }
    } catch (e) {
      // Fallback to cache if network fails
    }
    
    final cachedData = await tokenStorage.getUserData();
    if (cachedData != null) {
      return UserModel.fromJson(cachedData);
    }
    
    return null;
  }
}
