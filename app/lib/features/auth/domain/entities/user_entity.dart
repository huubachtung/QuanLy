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
  final String? employeeType; 
  final String? department;
  final String? departmentId;
  final DateTime? hiredDate;
  final double annualLeaveBalance;
  final double baseSalary;
  final String? workStartTime;
  final String? workEndTime;
  final List<LeaveBalanceEntity> leaveBalances;
  final String? position;

  const UserEntity({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.phone,
    this.avatar,
    this.employeeCode,
    required this.role,
    this.employeeType = 'official',
    this.department,
    this.departmentId,
    this.hiredDate,
    this.annualLeaveBalance = 12,
    this.baseSalary = 0,
    this.workStartTime = '08:30',
    this.workEndTime = '17:30',
    this.leaveBalances = const [],
    this.position,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? phone,
    String? avatar,
    String? employeeCode,
    String? role,
    String? employeeType,
    String? department,
    String? departmentId,
    DateTime? hiredDate,
    double? annualLeaveBalance,
    double? baseSalary,
    String? workStartTime,
    String? workEndTime,
    List<LeaveBalanceEntity>? leaveBalances,
    String? position,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      employeeCode: employeeCode ?? this.employeeCode,
      role: role ?? this.role,
      employeeType: employeeType ?? this.employeeType,
      department: department ?? this.department,
      departmentId: departmentId ?? this.departmentId,
      hiredDate: hiredDate ?? this.hiredDate,
      annualLeaveBalance: annualLeaveBalance ?? this.annualLeaveBalance,
      baseSalary: baseSalary ?? this.baseSalary,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      leaveBalances: leaveBalances ?? this.leaveBalances,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        employeeType,
        employeeCode,
        department,
        departmentId,
        position,
      ];
}

class LeaveBalanceEntity extends Equatable {
  final String leaveType;
  final String label;
  final double totalDays;
  final double usedDays;
  final double pendingDays;

  const LeaveBalanceEntity({
    required this.leaveType,
    required this.label,
    required this.totalDays,
    required this.usedDays,
    this.pendingDays = 0,
  });

  double get remainingDays => totalDays - usedDays - pendingDays;

  @override
  List<Object?> get props => [leaveType, label, totalDays, usedDays, pendingDays];
}
