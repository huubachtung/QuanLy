// ── Leave Request Model ───────────────────────────────────────
class LeaveRequestModel {
  final String id;
  final String userId;
  final String employeeCode;
  final String fromDate;
  final String toDate;
  final double totalDays;
  final LeaveType leaveType;
  final LeaveDuration leaveDuration;
  final String? startTime;
  final String? endTime;
  final String reason;
  final RequestStatus status;
  final String? approverId;
  final String? approverName;
  final String? rejectReason;
  final DateTime createdAt;
  final List<String> attachments;
  final double deductedLeave;

  const LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.leaveType,
    this.leaveDuration = LeaveDuration.fullDay,
    this.startTime,
    this.endTime,
    required this.reason,
    required this.status,
    this.approverId,
    this.approverName,
    this.rejectReason,
    required this.createdAt,
    this.attachments = const [],
    this.deductedLeave = 0.0,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    String parsedUserId = '';
    String parsedEmployeeCode = '';

    if (json['userId'] is Map) {
      parsedUserId = json['userId']['_id']?.toString() ?? '';
      parsedEmployeeCode = json['userId']['employeeCode']?.toString() ?? '';
    } else {
      parsedUserId = json['userId']?.toString() ?? json['user']?.toString() ?? '';
    }

    if (parsedEmployeeCode.isEmpty) {
      parsedEmployeeCode = json['employeeCode']?.toString() ??
          json['employee_code']?.toString() ??
          json['employeecode']?.toString() ??
          '';
    }

    return LeaveRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: parsedUserId,
      employeeCode: parsedEmployeeCode,
      fromDate: json['fromDate']?.toString() ?? json['startDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? json['endDate']?.toString() ?? '',
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      leaveType: _parseLeaveType(json['leaveType']?.toString() ?? json['type']?.toString()),
      leaveDuration: _parseLeaveDuration(json['leaveDuration']?.toString()),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: _parseRequestStatus(json['status']?.toString()),
      approverId: json['approverId']?.toString(),
      approverName: json['approverName']?.toString(),
      rejectReason: json['rejectReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      deductedLeave: (json['deductedLeave'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fromDate': fromDate,
      'toDate': toDate,
      'leaveType': leaveType.apiValue,
      'leaveDuration': leaveDuration.apiValue,
      'reason': reason,
    };

    if (startTime != null && startTime!.isNotEmpty) {
      map['startTime'] = startTime;
    }

    if (endTime != null && endTime!.isNotEmpty) {
      map['endTime'] = endTime;
    }

    return map;
  }
}

LeaveType _parseLeaveType(String? type) {
  switch (type?.toUpperCase()) {
    case 'ANNUAL_LEAVE': return LeaveType.annualLeave;
    case 'PREVIOUS_YEAR_LEAVE': return LeaveType.previousYearLeave;
    case 'COMPENSATORY_LEAVE': return LeaveType.compensatoryLeave;
    case 'SICK_LEAVE': return LeaveType.sickLeave;
    case 'SUMMER_LEAVE': return LeaveType.summerLeave;
    case 'UNPAID_LEAVE': return LeaveType.unpaidLeave;
    case 'MARRIAGE_LEAVE': return LeaveType.marriageLeave;
    case 'BEREAVEMENT_LEAVE': return LeaveType.bereavementLeave;
    case 'WIFE_BIRTH_SINGLE_NORMAL': return LeaveType.wifeBirthSingleNormal;
    case 'WIFE_BIRTH_SINGLE_SURGERY': return LeaveType.wifeBirthSingleSurgery;
    case 'WIFE_BIRTH_TWINS_NORMAL': return LeaveType.wifeBirthTwinsNormal;
    case 'WIFE_BIRTH_TWINS_SURGERY': return LeaveType.wifeBirthTwinsSurgery;
    case 'WIFE_BIRTH_TRIPLETS_NORMAL': return LeaveType.wifeBirthTriplets;
    case 'ADOPTION_UNDER_6M': return LeaveType.adoptionUnder6m;
    case 'CONTRACEPTION_LEAVE': return LeaveType.contraceptionLeave;
    case 'RECOVERY_LEAVE': return LeaveType.recoveryLeave;
    case 'HOLIDAYS_FOR_EXPATS': return LeaveType.holidaysForExpats;
    case 'MILITARY_LEAVE': return LeaveType.militaryLeave;
    case 'WIFE_MISCARRIAGE_OVER_22W': return LeaveType.wifeMiscarriageOver22w;
    case 'SHIFT_CHANGE': return LeaveType.shiftChange;
    case 'ONLINE_WORK': return LeaveType.onlineWork;
    case 'LATE_PERMISSION': return LeaveType.latePermission;
    case 'EARLY_LEAVE_REQUEST': return LeaveType.earlyLeaveRequest;
    case 'OTHER': return LeaveType.other;
    // Fallbacks from previous mapping
    case 'LEAVE_WITHOUT_PAY': return LeaveType.unpaidLeave;
    default: return LeaveType.other;
  }
}

LeaveDuration _parseLeaveDuration(String? duration) {
  switch (duration?.toUpperCase()) {
    case 'MORNING':
      return LeaveDuration.morning;
    case 'AFTERNOON':
      return LeaveDuration.afternoon;
    case 'FULL_DAY':
    default:
      return LeaveDuration.fullDay;
  }
}

RequestStatus _parseRequestStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'APPROVED':
      return RequestStatus.approved;
    case 'REJECTED':
      return RequestStatus.rejected;
    case 'CANCELLED':
      return RequestStatus.cancelled;
    case 'PENDING':
    default:
      return RequestStatus.pending;
  }
}

enum LeaveType {
  annualLeave,
  previousYearLeave,
  compensatoryLeave,
  sickLeave,
  summerLeave,
  unpaidLeave,
  marriageLeave,
  bereavementLeave,
  wifeBirthSingleNormal,
  wifeBirthSingleSurgery,
  wifeBirthTwinsNormal,
  wifeBirthTriplets,
  wifeBirthTwinsSurgery,
  adoptionUnder6m,
  contraceptionLeave,
  recoveryLeave,
  holidaysForExpats,
  militaryLeave,
  wifeMiscarriageOver22w,
  shiftChange,
  onlineWork,
  latePermission,
  earlyLeaveRequest,
  other,
}

extension LeaveTypeExt on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.annualLeave: return 'Nghỉ phép năm';
      case LeaveType.previousYearLeave: return 'Nghỉ phép năm trước';
      case LeaveType.compensatoryLeave: return 'Nghỉ bù';
      case LeaveType.sickLeave: return 'Nghỉ ốm có giấy bệnh viện';
      case LeaveType.summerLeave: return 'Nghỉ mát';
      case LeaveType.unpaidLeave: return 'Nghỉ không lương';
      case LeaveType.marriageLeave: return 'Nghỉ kết hôn';
      case LeaveType.bereavementLeave: return 'Nghỉ tang';
      case LeaveType.wifeBirthSingleNormal: return 'Vợ sinh 1 (thường)';
      case LeaveType.wifeBirthSingleSurgery: return 'Vợ sinh 1 (mổ)';
      case LeaveType.wifeBirthTwinsNormal: return 'Vợ sinh đôi (thường)';
      case LeaveType.wifeBirthTwinsSurgery: return 'Vợ sinh đôi (mổ)';
      case LeaveType.wifeBirthTriplets: return 'Vợ sinh ba (thường)';
      case LeaveType.adoptionUnder6m: return 'Nhận con nuôi < 6 tháng';
      case LeaveType.contraceptionLeave: return 'Thực hiện biện pháp tránh thai';
      case LeaveType.recoveryLeave: return 'Dưỡng sức sau ốm đau';
      case LeaveType.holidaysForExpats: return 'Nghỉ lễ cho người nước ngoài';
      case LeaveType.militaryLeave: return 'Khám nghĩa vụ quân sự';
      case LeaveType.wifeMiscarriageOver22w: return 'Vợ sẩy thai ≥ 22 tuần';
      case LeaveType.shiftChange: return 'Đổi ca làm việc';
      case LeaveType.onlineWork: return 'Làm việc Online (WFH)';
      case LeaveType.latePermission: return 'Xin đi muộn';
      case LeaveType.earlyLeaveRequest: return 'Xin về sớm';
      case LeaveType.other: return 'Lý do khác';
    }
  }

  bool get isSpecialRequest =>
      this == LeaveType.shiftChange ||
      this == LeaveType.onlineWork ||
      this == LeaveType.latePermission ||
      this == LeaveType.earlyLeaveRequest;

  bool get deductsAnnualLeave {
    return [
      LeaveType.annualLeave,
      LeaveType.previousYearLeave,
      LeaveType.compensatoryLeave,
      LeaveType.sickLeave,
      LeaveType.summerLeave,
      LeaveType.wifeBirthSingleNormal,
      LeaveType.wifeBirthSingleSurgery,
      LeaveType.wifeBirthTwinsNormal,
      LeaveType.wifeBirthTriplets,
      LeaveType.wifeBirthTwinsSurgery,
      LeaveType.adoptionUnder6m,
      LeaveType.contraceptionLeave,
      LeaveType.recoveryLeave,
      LeaveType.holidaysForExpats,
      LeaveType.militaryLeave,
      LeaveType.wifeMiscarriageOver22w,
      LeaveType.other,
    ].contains(this);
  }

  String get apiValue {
    switch (this) {
      case LeaveType.annualLeave: return 'ANNUAL_LEAVE';
      case LeaveType.previousYearLeave: return 'PREVIOUS_YEAR_LEAVE';
      case LeaveType.compensatoryLeave: return 'COMPENSATORY_LEAVE';
      case LeaveType.sickLeave: return 'SICK_LEAVE';
      case LeaveType.summerLeave: return 'SUMMER_LEAVE';
      case LeaveType.unpaidLeave: return 'UNPAID_LEAVE';
      case LeaveType.marriageLeave: return 'MARRIAGE_LEAVE';
      case LeaveType.bereavementLeave: return 'BEREAVEMENT_LEAVE';
      case LeaveType.wifeBirthSingleNormal: return 'WIFE_BIRTH_SINGLE_NORMAL';
      case LeaveType.wifeBirthSingleSurgery: return 'WIFE_BIRTH_SINGLE_SURGERY';
      case LeaveType.wifeBirthTwinsNormal: return 'WIFE_BIRTH_TWINS_NORMAL';
      case LeaveType.wifeBirthTwinsSurgery: return 'WIFE_BIRTH_TWINS_SURGERY';
      case LeaveType.wifeBirthTriplets: return 'WIFE_BIRTH_TRIPLETS_NORMAL';
      case LeaveType.adoptionUnder6m: return 'ADOPTION_UNDER_6M';
      case LeaveType.contraceptionLeave: return 'CONTRACEPTION_LEAVE';
      case LeaveType.recoveryLeave: return 'RECOVERY_LEAVE';
      case LeaveType.holidaysForExpats: return 'HOLIDAYS_FOR_EXPATS';
      case LeaveType.militaryLeave: return 'MILITARY_LEAVE';
      case LeaveType.wifeMiscarriageOver22w: return 'WIFE_MISCARRIAGE_OVER_22W';
      case LeaveType.shiftChange: return 'SHIFT_CHANGE';
      case LeaveType.onlineWork: return 'ONLINE_WORK';
      case LeaveType.latePermission: return 'LATE_PERMISSION';
      case LeaveType.earlyLeaveRequest: return 'EARLY_LEAVE_REQUEST';
      case LeaveType.other: return 'OTHER';
    }
  }
}

enum LeaveDuration { fullDay, morning, afternoon }

extension LeaveDurationExt on LeaveDuration {
  String get label {
    switch (this) {
      case LeaveDuration.fullDay: return 'Cả ngày (1.0)';
      case LeaveDuration.morning: return 'Ca sáng (0.5)';
      case LeaveDuration.afternoon: return 'Ca chiều (0.5)';
    }
  }

  double get days {
    switch (this) {
      case LeaveDuration.fullDay: return 1.0;
      case LeaveDuration.morning: return 0.5;
      case LeaveDuration.afternoon: return 0.5;
    }
  }

  String get apiValue {
    switch (this) {
      case LeaveDuration.fullDay: return 'FULL_DAY';
      case LeaveDuration.morning: return 'MORNING';
      case LeaveDuration.afternoon: return 'AFTERNOON';
    }
  }
}

enum RequestStatus { pending, approved, rejected, cancelled }

extension RequestStatusExt on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending: return 'Chờ duyệt';
      case RequestStatus.approved: return 'Đã duyệt';
      case RequestStatus.rejected: return 'Từ chối';
      case RequestStatus.cancelled: return 'Đã huỷ';
    }
  }

  String get apiValue {
    switch (this) {
      case RequestStatus.pending: return 'PENDING';
      case RequestStatus.approved: return 'APPROVED';
      case RequestStatus.rejected: return 'REJECTED';
      case RequestStatus.cancelled: return 'CANCELLED';
    }
  }
}
