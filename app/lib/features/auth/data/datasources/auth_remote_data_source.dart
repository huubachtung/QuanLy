import '../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/mock/mock_data.dart'; // Vẫn dùng mock data cũ tạm thời

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (username.isNotEmpty && password.isNotEmpty) {
      final mock = MockData.currentUser;
      return UserModel(
        id: mock.id,
        username: mock.username,
        displayName: mock.displayName,
        email: mock.email,
        phone: mock.phone,
        avatar: mock.avatar,
        employeeCode: mock.employeeCode,
        role: mock.role,
        employeeType: mock.employeeType,
        department: mock.department,
        departmentId: mock.departmentId,
      );
    } else {
      throw ServerException();
    }
  }
}
