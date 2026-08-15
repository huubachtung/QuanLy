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
    super.hiredDate,
    super.annualLeaveBalance = 12,
    super.baseSalary = 0,
    super.workStartTime = '08:30',
    super.workEndTime = '17:30',
    super.leaveBalances = const [],
  });

  static bool _isMongoId(String str) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(str.trim());

  static String? _parseDepartmentName(Map<String, dynamic> json) {
    if (json['departmentName'] != null &&
        json['departmentName'].toString().trim().isNotEmpty) {
      return json['departmentName'].toString().trim();
    }
    final dept = json['department'];
    if (dept is Map) {
      return dept['name']?.toString() ??
          dept['departmentName']?.toString() ??
          dept['title']?.toString();
    }
    if (dept != null) {
      final deptStr = dept.toString().trim();
      if (deptStr.isNotEmpty && !_isMongoId(deptStr)) {
        return deptStr;
      }
    }
    return null;
  }

  static String? _parseDepartmentId(Map<String, dynamic> json) {
    if (json['departmentId'] != null &&
        json['departmentId'].toString().trim().isNotEmpty) {
      return json['departmentId'].toString().trim();
    }
    final dept = json['department'];
    if (dept is Map) {
      return dept['_id']?.toString() ?? dept['id']?.toString();
    }
    if (dept != null) {
      final deptStr = dept.toString().trim();
      if (deptStr.isNotEmpty && _isMongoId(deptStr)) {
        return deptStr;
      }
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['display_name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      employeeCode: json['employeeCode']?.toString() ??
          json['employee_code']?.toString() ??
          json['employeecode']?.toString() ??
          json['code']?.toString(),
      role: json['role']?.toString() ?? 'member',
      employeeType: json['employeeType']?.toString() ?? 'official',
      department: _parseDepartmentName(json),
      departmentId: _parseDepartmentId(json),
      hiredDate: json['hiredDate'] != null
          ? DateTime.tryParse(json['hiredDate'].toString())?.toLocal()
          : null,
      annualLeaveBalance: (json['annualLeaveBalance'] ?? 12).toDouble(),
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      workStartTime: json['workStartTime']?.toString() ?? '08:30',
      workEndTime: json['workEndTime']?.toString() ?? '17:30',
      leaveBalances: (json['leaveBalances'] as List<dynamic>?)
              ?.map(
                  (e) => LeaveBalanceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id, // Save _id for consistency
      'username': username,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'employeeCode': employeeCode,
      'role': role,
      'employeeType': employeeType,
      'department': (department != null || departmentId != null)
          ? {
              '_id': departmentId ?? '',
              'name': department ?? '',
            }
          : null,
      'departmentName': department,
      'departmentId': departmentId,
      'hiredDate': hiredDate?.toIso8601String(),
      'annualLeaveBalance': annualLeaveBalance,
      'baseSalary': baseSalary,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'leaveBalances':
          leaveBalances.map((e) => (e as LeaveBalanceModel).toJson()).toList(),
    };
  }
}

class LeaveBalanceModel extends LeaveBalanceEntity {
  const LeaveBalanceModel({
    required super.leaveType,
    required super.label,
    required super.totalDays,
    required super.usedDays,
    super.pendingDays = 0,
  });

  static String _getLabelForLeaveType(String leaveType) {
    switch (leaveType.toUpperCase()) {
      case 'ANNUAL_LEAVE':
        return 'Nghỉ phép năm';
      case 'PREVIOUS_YEAR_LEAVE':
        return 'Nghỉ phép năm trước';
      case 'COMPENSATORY_LEAVE':
        return 'Nghỉ bù';
      case 'SICK_LEAVE':
        return 'Nghỉ ốm có giấy bệnh viện';
      case 'SUMMER_LEAVE':
        return 'Nghỉ mát';
      case 'UNPAID_LEAVE':
        return 'Nghỉ không lương';
      case 'MARRIAGE_LEAVE':
        return 'Nghỉ kết hôn';
      case 'BEREAVEMENT_LEAVE':
        return 'Nghỉ tang';
      case 'WIFE_BIRTH_SINGLE_NORMAL':
        return 'Vợ sinh 1 (thường)';
      case 'WIFE_BIRTH_SINGLE_SURGERY':
        return 'Vợ sinh 1 (mổ)';
      case 'WIFE_BIRTH_TWINS_NORMAL':
        return 'Vợ sinh đôi (thường)';
      case 'WIFE_BIRTH_TWINS_SURGERY':
        return 'Vợ sinh đôi (mổ)';
      case 'WIFE_BIRTH_TRIPLETS_NORMAL':
        return 'Vợ sinh ba (thường)';
      case 'ADOPTION_UNDER_6M':
        return 'Nhận con nuôi < 6 tháng';
      case 'CONTRACEPTION_LEAVE':
        return 'Thực hiện biện pháp tránh thai';
      case 'RECOVERY_LEAVE':
        return 'Dưỡng sức sau ốm đau';
      case 'HOLIDAYS_FOR_EXPATS':
        return 'Nghỉ lễ cho người nước ngoài';
      case 'MILITARY_LEAVE':
        return 'Khám nghĩa vụ quân sự';
      case 'WIFE_MISCARRIAGE_OVER_22W':
        return 'Vợ sẩy thai ≥ 22 tuần';
      case 'SHIFT_CHANGE':
        return 'Đổi ca làm việc';
      case 'ONLINE_WORK':
        return 'Làm việc Online (WFH)';
      case 'LATE_PERMISSION':
        return 'Xin đi muộn';
      case 'EARLY_LEAVE_REQUEST':
        return 'Xin về sớm';
      case 'OTHER':
        return 'Lý do khác';
      default:
        return 'Lý do khác';
    }
  }

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    final type = json['leaveType']?.toString() ?? '';
    final labelStr = json['label']?.toString() ?? '';

    return LeaveBalanceModel(
      leaveType: type,
      label: labelStr.isNotEmpty ? labelStr : _getLabelForLeaveType(type),
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      usedDays: (json['usedDays'] ?? 0).toDouble(),
      pendingDays: (json['pendingDays'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaveType': leaveType,
      'label': label,
      'totalDays': totalDays,
      'usedDays': usedDays,
      'pendingDays': pendingDays,
    };
  }
}
