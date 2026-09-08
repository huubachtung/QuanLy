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
  final String? shiftChangeDate;
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
    this.shiftChangeDate,
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

    String? parsedApproverId;
    String? parsedApproverName;
    if (json['approverId'] is Map) {
      parsedApproverId = json['approverId']['_id']?.toString();
      parsedApproverName = json['approverId']['displayName']?.toString() ??
          json['approverId']['username']?.toString();
    } else {
      parsedApproverId = json['approverId']?.toString();
      parsedApproverName = json['approverName']?.toString();
    }

    return LeaveRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: parsedUserId,
      employeeCode: parsedEmployeeCode,
      fromDate: json['fromDate']?.toString() ?? json['startDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? json['endDate']?.toString() ?? '',
      shiftChangeDate: json['shiftChangeDate']?.toString(),
      totalDays: (json['totalDays'] ?? 0).toDouble(),
      leaveType: _parseLeaveType(json['leaveType']?.toString() ?? json['type']?.toString()),
      leaveDuration: _parseLeaveDuration(json['leaveDuration']?.toString()),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: _parseRequestStatus(json['status']?.toString()),
      approverId: parsedApproverId,
      approverName: parsedApproverName,
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

    if (shiftChangeDate != null && shiftChangeDate!.isNotEmpty) {
      map['shiftChangeDate'] = shiftChangeDate;
    }

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
      case LeaveType.sickLeave: return 'Nghỉ ốm';
      case LeaveType.summerLeave: return 'Nghỉ hè';
      case LeaveType.unpaidLeave: return 'Nghỉ không lương';
      case LeaveType.marriageLeave: return 'Nghỉ kết hôn';
      case LeaveType.bereavementLeave: return 'Nghỉ tang';
      case LeaveType.wifeBirthSingleNormal: return 'Nghỉ vợ sinh thường (đơn)';
      case LeaveType.wifeBirthSingleSurgery: return 'Nghỉ vợ sinh mổ (đơn)';
      case LeaveType.wifeBirthTwinsNormal: return 'Nghỉ vợ sinh thường (đôi)';
      case LeaveType.wifeBirthTwinsSurgery: return 'Nghỉ vợ sinh mổ (đôi/ba)';
      case LeaveType.wifeBirthTriplets: return 'Nghỉ vợ sinh thường (ba)';
      case LeaveType.adoptionUnder6m: return 'Nhận con nuôi dưới 6 tháng';
      case LeaveType.contraceptionLeave: return 'Nghỉ tránh thai';
      case LeaveType.recoveryLeave: return 'Nghỉ phục hồi sức khoẻ';
      case LeaveType.holidaysForExpats: return 'Nghỉ lễ người nước ngoài';
      case LeaveType.militaryLeave: return 'Nghỉ huấn luyện quân sự';
      case LeaveType.wifeMiscarriageOver22w: return 'Nghỉ sẩy thai ≥22 tuần';
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

  bool get isSingleDayOnly =>
      this == LeaveType.latePermission ||
      this == LeaveType.earlyLeaveRequest;

  bool get isTimeBasedRequest =>
      this == LeaveType.shiftChange ||
      this == LeaveType.latePermission ||
      this == LeaveType.earlyLeaveRequest;

  bool get deductsAnnualLeave {
    return this == LeaveType.annualLeave;
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

// ── Leave Stat & Response Models ──────────────────────────────
class LeaveStatItem {
  final String leaveType;
  final String label;
  final bool deductsLeave;
  final double max;
  final double approved;
  final double pending;
  final double? remaining;
  final bool useSharedPool;
  final String? limitUnit;
  final bool govMandated;

  const LeaveStatItem({
    required this.leaveType,
    required this.label,
    required this.deductsLeave,
    required this.max,
    required this.approved,
    required this.pending,
    this.remaining,
    this.useSharedPool = false,
    this.limitUnit,
    this.govMandated = false,
  });

  bool get isSpecialRequest =>
      leaveType == 'SHIFT_CHANGE' ||
      leaveType == 'ONLINE_WORK' ||
      leaveType == 'LATE_PERMISSION' ||
      leaveType == 'EARLY_LEAVE_REQUEST';

  factory LeaveStatItem.fromJson(String key, Map<String, dynamic> json) {
    final maxVal = (json['max'] as num?)?.toDouble() ?? 0.0;
    final approvedVal = (json['approved'] as num?)?.toDouble() ?? 0.0;
    final pendingVal = (json['pending'] as num?)?.toDouble() ?? 0.0;
    final rawRemaining = (json['remaining'] as num?)?.toDouble();
    final remainingVal = rawRemaining ?? (maxVal > 0 ? (maxVal - approvedVal - pendingVal) : 0.0);

    return LeaveStatItem(
      leaveType: key,
      label: json['label']?.toString() ?? key,
      deductsLeave: json['deductsLeave'] == true,
      max: maxVal,
      approved: approvedVal,
      pending: pendingVal,
      remaining: remainingVal,
      useSharedPool: json['useSharedPool'] == true,
      limitUnit: json['limitUnit']?.toString(),
      govMandated: json['govMandated'] == true,
    );
  }
}

class LeaveDataResponse {
  final List<LeaveRequestModel> requests;
  final double annualLeaveBalance;
  final double annualMaxDays;
  final double pendingDeducts;
  final Map<String, LeaveStatItem> stats;

  const LeaveDataResponse({
    required this.requests,
    this.annualLeaveBalance = 12.0,
    this.annualMaxDays = 12.0,
    this.pendingDeducts = 0.0,
    this.stats = const {},
  });

  factory LeaveDataResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    final requests = rawList
        .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final statsMap = <String, LeaveStatItem>{};
    if (json['stats'] is Map<String, dynamic>) {
      final rawStats = json['stats'] as Map<String, dynamic>;
      rawStats.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          statsMap[k] = LeaveStatItem.fromJson(k, v);
        }
      });
    }

    return LeaveDataResponse(
      requests: requests,
      annualLeaveBalance: (json['annualLeaveBalance'] as num?)?.toDouble() ?? 12.0,
      annualMaxDays: (json['annualMaxDays'] as num?)?.toDouble() ?? 12.0,
      pendingDeducts: (json['pendingDeducts'] as num?)?.toDouble() ?? 0.0,
      stats: statsMap,
    );
  }
}

