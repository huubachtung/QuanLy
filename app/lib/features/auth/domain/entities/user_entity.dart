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
  final DateTime? hiredDate;
  final double annualLeaveBalance;
  final double baseSalary;
  final String? workStartTime;
  final String? workEndTime;
  final List<LeaveBalanceEntity> leaveBalances;

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
  });

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
