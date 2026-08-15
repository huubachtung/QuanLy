// ── Overtime Status ──────────────────────────────────────────────
enum OtStatus {
  none,
  pendingConfirmation,
  pending,
  approved,
  rejected,
}

typedef OtRequestStatus = OtStatus;

extension OtStatusExt on OtStatus {
  String get value {
    switch (this) {
      case OtStatus.none:
        return 'NONE';
      case OtStatus.pendingConfirmation:
        return 'PENDING_CONFIRMATION';
      case OtStatus.pending:
        return 'PENDING';
      case OtStatus.approved:
        return 'APPROVED';
      case OtStatus.rejected:
        return 'REJECTED';
    }
  }

  String get label {
    switch (this) {
      case OtStatus.none:
        return 'Không có OT';
      case OtStatus.pendingConfirmation:
        return 'Chờ xác nhận';
      case OtStatus.pending:
        return 'Chờ duyệt';
      case OtStatus.approved:
        return 'Đã duyệt';
      case OtStatus.rejected:
        return 'Từ chối';
    }
  }

  static OtStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING_CONFIRMATION':
        return OtStatus.pendingConfirmation;
      case 'PENDING':
        return OtStatus.pending;
      case 'APPROVED':
        return OtStatus.approved;
      case 'REJECTED':
        return OtStatus.rejected;
      case 'NONE':
      case 'NO_OT':
      case 'NO OT':
      default:
        return OtStatus.none;
    }
  }
}

extension OtRequestStatusExt on OtRequestStatus {
  static OtRequestStatus get noOt => OtStatus.none;
}

// ── Overtime Request Model (Monthly Sheet Item & Single Request) ─
class OvertimeModel {
  final String? id;
  final String date; // YYYY-MM-DD
  final int dayOfWeek; // 0: CN, 1: T2, ..., 6: T7
  final String? checkIn;
  final String? checkOut;
  final double calculatedOtHours; // Giờ máy tính
  final double requestedOtHours;  // Giờ đề nghị
  final String reason;
  final OtStatus status;
  final String rejectReason;
  final String approverName;

  const OvertimeModel({
    this.id,
    required this.date,
    this.dayOfWeek = 0,
    this.checkIn,
    this.checkOut,
    this.calculatedOtHours = 0.0,
    this.requestedOtHours = 0.0,
    this.reason = '',
    this.status = OtStatus.none,
    this.rejectReason = '',
    this.approverName = '',
  });

  // Backward compatibility getters
  double get systemOtHours => calculatedOtHours;
  double get requestedHours => requestedOtHours;
  String get userId => '';

  bool get isEditable => status != OtStatus.approved;

  factory OvertimeModel.fromJson(Map<String, dynamic> json) {
    final rawCheckIn = _formatTimeString(json['checkIn']?.toString());
    final rawCheckOut = _formatTimeString(json['checkOut']?.toString());

    return OvertimeModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      date: json['date']?.toString() ?? '',
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
      checkIn: rawCheckIn,
      checkOut: rawCheckOut,
      calculatedOtHours: (json['calculatedOtHours'] as num?)?.toDouble() ??
          (json['systemOtHours'] as num?)?.toDouble() ??
          0.0,
      requestedOtHours: (json['requestedOtHours'] as num?)?.toDouble() ??
          (json['requestedHours'] as num?)?.toDouble() ??
          (json['hours'] as num?)?.toDouble() ??
          0.0,
      reason: json['reason']?.toString() ?? '',
      status: OtStatusExt.fromString(json['status']?.toString()),
      rejectReason: json['rejectReason']?.toString() ?? '',
      approverName: json['approverName']?.toString() ??
          (json['approverId'] is Map
              ? json['approverId']['displayName']?.toString() ??
                  json['approverId']['username']?.toString() ??
                  ''
              : ''),
    );
  }

  Map<String, dynamic> toSingleJson() {
    return {
      'date': date,
      'hours': requestedOtHours,
      'reason': reason.trim(),
    };
  }

  Map<String, dynamic> toBulkEntryJson() {
    return {
      'date': date,
      'hours': requestedOtHours,
      'reason': reason.trim(),
    };
  }

  OvertimeModel copyWith({
    String? id,
    String? date,
    int? dayOfWeek,
    String? checkIn,
    String? checkOut,
    double? calculatedOtHours,
    double? requestedOtHours,
    String? reason,
    OtStatus? status,
    String? rejectReason,
    String? approverName,
  }) {
    return OvertimeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      calculatedOtHours: calculatedOtHours ?? this.calculatedOtHours,
      requestedOtHours: requestedOtHours ?? this.requestedOtHours,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      approverName: approverName ?? this.approverName,
    );
  }
}

String? _formatTimeString(String? raw) {
  if (raw == null || raw.isEmpty || raw == 'null') return null;
  if (raw.contains('T') || raw.endsWith('Z')) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
  return raw;
}
