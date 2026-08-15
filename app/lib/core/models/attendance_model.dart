// ── Attendance Model ──────────────────────────────────────────
class AttendanceModel {
  final String id;
  final String userId;
  final String date; // DD/MM/YYYY
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

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: (json['user'] is Map ? json['user']['_id'] : json['user'])
              ?.toString() ??
          json['userId']?.toString() ??
          '',
      date: json['date']?.toString() ?? '',
      checkIn: json['checkIn'] != null
          ? DateTime.tryParse(json['checkIn'].toString())?.toLocal()
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.tryParse(json['checkOut'].toString())?.toLocal()
          : null,
      normalHours: _parseDouble(json['normalHours']),
      overtimeHours: _parseDouble(json['overtimeHours']),
      otStatus: _parseOtStatus(json['otStatus']?.toString()),
      dailyCong: _parseDouble(json['dailyCong']),
      status: _parseAttendanceStatus(json['status']?.toString()),
      note: json['note']?.toString() ?? '',
      isLeave: _parseBool(json['isLeave']),
    );
  }
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

bool _parseBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is num) return val != 0;
  if (val is String) return val.toLowerCase() == 'true' || val == '1';
  return false;
}

AttendanceStatus _parseAttendanceStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'done':
      return AttendanceStatus.done;
    case 'late':
      return AttendanceStatus.late;
    case 'earlyleave':
      return AttendanceStatus.earlyLeave;
    case 'lateearlyleave':
      return AttendanceStatus.lateEarlyLeave;
    case 'absent':
      return AttendanceStatus.absent;
    case 'pending':
      return AttendanceStatus.pending;
    case 'leave':
      return AttendanceStatus.leave;
    case 'off':
      return AttendanceStatus.off;
    default:
      return AttendanceStatus.done;
  }
}

OtStatus _parseOtStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return OtStatus.pending;
    case 'approved':
      return OtStatus.approved;
    case 'rejected':
      return OtStatus.rejected;
    case 'none':
    default:
      return OtStatus.none;
  }
}

enum AttendanceStatus {
  done, // Hoàn thành
  late, // Đi muộn
  earlyLeave, // Về sớm
  lateEarlyLeave, // Đi muộn & Về sớm
  absent, // Vắng mặt
  pending, // Chưa chấm công về
  leave, // Nghỉ phép
  off, // Ngày off
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.done:
        return 'Hoàn thành';
      case AttendanceStatus.late:
        return 'Đi muộn';
      case AttendanceStatus.earlyLeave:
        return 'Về sớm';
      case AttendanceStatus.lateEarlyLeave:
        return 'Đi muộn & Về sớm';
      case AttendanceStatus.absent:
        return 'Vắng mặt';
      case AttendanceStatus.pending:
        return 'Chưa chấm công về';
      case AttendanceStatus.leave:
        return 'Nghỉ phép';
      case AttendanceStatus.off:
        return 'Ngày nghỉ';
    }
  }
}

enum OtStatus { none, pending, approved, rejected }

extension OtStatusExt on OtStatus {
  String get label {
    switch (this) {
      case OtStatus.none:
        return 'Không có OT';
      case OtStatus.pending:
        return 'Chờ duyệt';
      case OtStatus.approved:
        return 'Đã duyệt';
      case OtStatus.rejected:
        return 'Từ chối';
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

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      workDays:
          _parseInt(json['presentDays']) ?? _parseInt(json['workDays']) ?? 0,
      totalNormalHours: _parseDouble(json['normalHours']) > 0
          ? _parseDouble(json['normalHours'])
          : _parseDouble(json['totalNormalHours']),
      approvedOtHours: _parseDouble(json['overtimeHours']) > 0
          ? _parseDouble(json['overtimeHours'])
          : _parseDouble(json['approvedOtHours']),
      pendingOtHours: _parseDouble(json['pendingOtHours']),
      rejectedOtHours: _parseDouble(json['rejectedOtHours']),
      totalCong: _parseDouble(json['totalCong']),
      totalOtHours: _parseDouble(json['overtimeHours']) > 0
          ? _parseDouble(json['overtimeHours'])
          : _parseDouble(json['totalOtHours']),
    );
  }
}

class AttendanceResponseModel {
  final AttendanceSummary summary;
  final List<AttendanceModel> records;

  const AttendanceResponseModel({
    required this.summary,
    required this.records,
  });

  factory AttendanceResponseModel.fromJson(Map<String, dynamic> json) {
    return AttendanceResponseModel(
      summary: AttendanceSummary.fromJson(json),
      records: (json['records'] as List?)
              ?.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
