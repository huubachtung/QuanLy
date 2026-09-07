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
    // 1. Thử lấy chi tiết phòng ban qua /api/department/{id}
    try {
      final response = await apiClient.dio.get('/api/department/${user.departmentId}');
      final data = response.data;
      final deptData = (data is Map && data['data'] != null) ? data['data'] : data;
      if (deptData is Map) {
        final deptName = deptData['name']?.toString() ?? deptData['departmentName']?.toString();
        if (deptName != null && deptName.isNotEmpty) {
          return user.copyWith(department: deptName);
        }
      }
    } catch (_) {}

    // 2. Thử lấy danh sách tất cả phòng ban qua /api/department và lọc theo id
    try {
      final response = await apiClient.dio.get('/api/department');
      final data = response.data;
      final list = (data is Map && data['data'] is List)
          ? data['data'] as List
          : (data is List ? data : []);
      for (final item in list) {
        if (item is Map) {
          final id = item['_id']?.toString() ?? item['id']?.toString();
          if (id == user.departmentId) {
            final deptName = item['name']?.toString() ?? item['departmentName']?.toString();
            if (deptName != null && deptName.isNotEmpty) {
              return user.copyWith(department: deptName);
            }
          }
        }
      }
    } catch (_) {}

    return user;
  }

  Future<UserModel> _fetchFullUserProfile(String userId, UserModel fallback) async {
    for (final path in [ApiConstants.userProfile(userId), '${ApiConstants.users}/$userId']) {
      try {
        final response = await apiClient.dio.get(path);
        final data = response.data;
        Map<String, dynamic>? userMap;
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            userMap = data['data'] as Map<String, dynamic>;
          } else if (data['user'] is Map<String, dynamic>) {
            userMap = data['user'] as Map<String, dynamic>;
          } else if (data['username'] != null || data['_id'] != null) {
            userMap = data;
          }
        }
        if (userMap != null) {
          var user = UserModel.fromJson(userMap);
          if (user.department == null && user.departmentId != null) {
            user = await _enrichUserWithDepartment(user);
          }
          return user;
        }
      } catch (_) {}
    }
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

    final cachedData = await tokenStorage.getUserData();
    UserModel? cachedUser;
    if (cachedData != null) {
      try {
        cachedUser = UserModel.fromJson(cachedData);
      } catch (_) {}
    }

    try {
      final dummyUser = cachedUser ?? UserModel(
        id: userId,
        username: '',
        displayName: '',
        email: '',
        role: 'member',
      );
      final user = await _fetchFullUserProfile(userId, dummyUser);
      if (user.id.isNotEmpty && (user.username.isNotEmpty || user.displayName.isNotEmpty)) {
        await tokenStorage.saveUserData(user.toJson());
        return user;
      }
    } catch (_) {}

    if (cachedUser != null) {
      if (cachedUser.department == null && cachedUser.departmentId != null) {
        cachedUser = await _enrichUserWithDepartment(cachedUser);
      }
      return cachedUser;
    }

    return null;
  }
}
