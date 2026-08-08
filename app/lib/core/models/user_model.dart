// ── User Model ────────────────────────────────────────────────
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? employeeCode;
  final String role; // admin, leader, member, accountant
  final String employeeType; // FULL_TIME, PART_TIME, INTERN...
  final String? department;
  final String? departmentId;
  final DateTime? hiredDate;
  final double annualLeaveBalance;
  final double baseSalary;
  final String? workStartTime;
  final String? workEndTime;
  final List<LeaveBalance> leaveBalances;

  const UserModel({
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
    this.hiredDate,
    this.annualLeaveBalance = 12,
    this.baseSalary = 0,
    this.workStartTime = '08:30',
    this.workEndTime = '17:30',
    this.leaveBalances = const [],
  });
}

class LeaveBalance {
  final String leaveType;
  final String label;
  final double totalDays;
  final double usedDays;
  final double pendingDays;

  const LeaveBalance({
    required this.leaveType,
    required this.label,
    required this.totalDays,
    required this.usedDays,
    this.pendingDays = 0,
  });

  double get remainingDays => totalDays - usedDays - pendingDays;
}
