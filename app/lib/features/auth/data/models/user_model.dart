import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.displayName,
    required super.email,
    super.phone,
    super.avatar,
    super.employeeCode,
    required super.role,
    required super.employeeType,
    super.department,
    super.departmentId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      displayName: json['displayName'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      employeeCode: json['employeeCode'],
      role: json['role'],
      employeeType: json['employeeType'],
      department: json['department'],
      departmentId: json['departmentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'employeeCode': employeeCode,
      'role': role,
      'employeeType': employeeType,
      'department': department,
      'departmentId': departmentId,
    };
  }
}
