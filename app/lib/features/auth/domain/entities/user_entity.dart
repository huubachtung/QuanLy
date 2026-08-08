import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? employeeCode;
  final String role; 
  final String employeeType; 
  final String? department;
  final String? departmentId;

  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.phone,
    this.avatar,
    this.employeeCode,
    required this.role,
    required this.employeeType,
    this.department,
    this.departmentId,
  });

  @override
  List<Object?> get props => [id, username, email, role, employeeType];
}
