import 'dart:convert';
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
    super.employeeType = 'official',
    super.department,
    super.departmentId,
    super.hiredDate,
    super.annualLeaveBalance = 12,
    super.baseSalary = 0,
    super.workStartTime = '08:30',
    super.workEndTime = '17:30',
    super.leaveBalances = const [],
    super.position,
  });

  static bool _isMongoId(String str) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(str.trim());

  static double _parseDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.trim()) ?? defaultVal;
    }
    return defaultVal;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val.toLocal();
    if (val is String) {
      return DateTime.tryParse(val.trim())?.toLocal();
    }
    return null;
  }

  static String? _parseAvatar(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'null' ||
          trimmed.toLowerCase() == 'undefined') {
        return null;
      }
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            final link = decoded['url']?.toString() ??
                decoded['secure_url']?.toString() ??
                decoded['link']?.toString() ??
                decoded['path']?.toString();
            if (link != null && link.isNotEmpty) return link.trim();
          }
        } catch (_) {}
      }
      return trimmed;
    }
    if (raw is Map) {
      final link = raw['url']?.toString() ??
          raw['secure_url']?.toString() ??
          raw['link']?.toString() ??
          raw['path']?.toString();
      if (link != null && link.isNotEmpty) return link.trim();
    }
    return raw.toString().trim();
  }

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
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? json['work_email']?.toString() ?? '',
      phone: json['phone']?.toString() ??
          json['phone_number']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['home_phone']?.toString(),
      avatar: _parseAvatar(json['avatar'] ?? json['avatarUrl'] ?? json['avatar_url'] ?? json['photoUrl'] ?? json['picture']),
      employeeCode: json['employeeCode']?.toString() ??
          json['employee_code']?.toString() ??
          json['employeecode']?.toString() ??
          json['code']?.toString(),
      role: json['role']?.toString() ?? 'member',
      employeeType: json['employeeType']?.toString() ??
          json['employee_type']?.toString() ??
          json['contract_type']?.toString() ??
          'official',
      department: _parseDepartmentName(json),
      departmentId: _parseDepartmentId(json),
      position: json['position']?.toString() ??
          json['job_title']?.toString() ??
          json['jobTitle']?.toString(),
      hiredDate: _parseDate(json['hiredDate'] ??
          json['hired_date'] ??
          json['contract_start_date'] ??
          json['contractStartDate']),
      annualLeaveBalance: _parseDouble(
        json['annualLeaveBalance'] ?? json['annual_leave_balance'],
        12.0,
      ),
      baseSalary: _parseDouble(
        json['baseSalary'] ?? json['base_salary'] ?? json['fix_package'],
        0.0,
      ),
      workStartTime: json['workStartTime']?.toString() ??
          json['work_start_time']?.toString() ??
          '08:30',
      workEndTime: json['workEndTime']?.toString() ??
          json['work_end_time']?.toString() ??
          '17:30',
      leaveBalances: ((json['leaveBalances'] ?? json['leave_balances']) as List<dynamic>?)
              ?.map(
                  (e) => LeaveBalanceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'username': username,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'employeeCode': employeeCode,
      'role': role,
      'employeeType': employeeType,
      'position': position,
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
    final type = json['leaveType']?.toString() ?? json['type']?.toString() ?? '';
    final labelStr = json['label']?.toString() ?? '';

    return LeaveBalanceModel(
      leaveType: type,
      label: labelStr.isNotEmpty ? labelStr : _getLabelForLeaveType(type),
      totalDays: UserModel._parseDouble(json['totalDays'] ?? json['maxDays'] ?? json['max'], 0.0),
      usedDays: UserModel._parseDouble(json['usedDays'] ?? json['approved'], 0.0),
      pendingDays: UserModel._parseDouble(json['pendingDays'] ?? json['pending'], 0.0),
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
