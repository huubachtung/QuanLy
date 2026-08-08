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
  });
}

enum LeaveType {
  annualLeave, previousYearLeave, compensatoryLeave, sickLeave,
  summerLeave, unpaidLeave, marriageLeave, bereavementLeave,
  wifeBirthSingleNormal, wifeBirthSingleSurgery, wifeBirthTwinsNormal,
  wifeBirthTriplets, wifeBirthTwinsSurgery, adoptionUnder6m,
  contraceptionLeave, recoveryLeave, holidaysForExpats, militaryLeave,
  wifeMiscarriageOver22w,
  shiftChange, onlineWork, latePermission, earlyLeaveRequest, other,
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
      case LeaveType.wifeBirthSingleNormal: return 'Vợ sinh thường (đơn)';
      case LeaveType.wifeBirthSingleSurgery: return 'Vợ sinh mổ (đơn)';
      case LeaveType.wifeBirthTwinsNormal: return 'Vợ sinh thường (đôi)';
      case LeaveType.wifeBirthTriplets: return 'Vợ sinh thường (ba)';
      case LeaveType.wifeBirthTwinsSurgery: return 'Vợ sinh mổ (đôi/ba)';
      case LeaveType.adoptionUnder6m: return 'Nhận con nuôi < 6 tháng';
      case LeaveType.contraceptionLeave: return 'Nghỉ tránh thai';
      case LeaveType.recoveryLeave: return 'Nghỉ phục hồi sức khoẻ';
      case LeaveType.holidaysForExpats: return 'Nghỉ lễ người nước ngoài';
      case LeaveType.militaryLeave: return 'Nghỉ huấn luyện quân sự';
      case LeaveType.wifeMiscarriageOver22w: return 'Vợ sẩy thai ≥ 22 tuần';
      case LeaveType.shiftChange: return 'Đổi ca làm';
      case LeaveType.onlineWork: return 'Làm Online';
      case LeaveType.latePermission: return 'Xin đi muộn';
      case LeaveType.earlyLeaveRequest: return 'Xin về sớm';
      case LeaveType.other: return 'Khác';
    }
  }

  bool get isSpecialRequest =>
    this == LeaveType.shiftChange ||
    this == LeaveType.onlineWork ||
    this == LeaveType.latePermission ||
    this == LeaveType.earlyLeaveRequest;

  bool get deductsAnnualLeave {
    return [
      LeaveType.annualLeave, LeaveType.previousYearLeave,
      LeaveType.compensatoryLeave, LeaveType.sickLeave,
      LeaveType.summerLeave, LeaveType.other,
    ].contains(this);
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
}
