// ── Attendance Model ──────────────────────────────────────────
class AttendanceModel {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double normalHours;
  final double overtimeHours;
  final OtStatus otStatus;
  final double dailyCong;
  final AttendanceStatus status;
  final String note;
  final bool isLeave;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.normalHours = 0,
    this.overtimeHours = 0,
    this.otStatus = OtStatus.none,
    this.dailyCong = 0,
    required this.status,
    this.note = '',
    this.isLeave = false,
  });
}

enum AttendanceStatus {
  done,          // Hoàn thành
  late,          // Đi muộn
  earlyLeave,    // Về sớm
  lateEarlyLeave,// Đi muộn & Về sớm
  absent,        // Vắng mặt
  pending,       // Chưa chấm công về
  leave,         // Nghỉ phép
  off,           // Ngày off
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.done: return 'Hoàn thành';
      case AttendanceStatus.late: return 'Đi muộn';
      case AttendanceStatus.earlyLeave: return 'Về sớm';
      case AttendanceStatus.lateEarlyLeave: return 'Đi muộn & Về sớm';
      case AttendanceStatus.absent: return 'Vắng mặt';
      case AttendanceStatus.pending: return 'Chưa chấm công về';
      case AttendanceStatus.leave: return 'Nghỉ phép';
      case AttendanceStatus.off: return 'Ngày nghỉ';
    }
  }
}

enum OtStatus { none, pending, approved, rejected }

extension OtStatusExt on OtStatus {
  String get label {
    switch (this) {
      case OtStatus.none: return 'Không có OT';
      case OtStatus.pending: return 'Chờ duyệt';
      case OtStatus.approved: return 'Đã duyệt';
      case OtStatus.rejected: return 'Từ chối';
    }
  }
}

// ── Attendance Summary ─────────────────────────────────────────
class AttendanceSummary {
  final int workDays;
  final double totalNormalHours;
  final double approvedOtHours;
  final double pendingOtHours;
  final double rejectedOtHours;
  final double totalCong;
  final double totalOtHours;

  const AttendanceSummary({
    this.workDays = 0,
    this.totalNormalHours = 0,
    this.approvedOtHours = 0,
    this.pendingOtHours = 0,
    this.rejectedOtHours = 0,
    this.totalCong = 0,
    this.totalOtHours = 0,
  });
}
