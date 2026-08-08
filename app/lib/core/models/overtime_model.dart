// ── Overtime Request Model ────────────────────────────────────
class OvertimeModel {
  final String id;
  final String userId;
  final String date; // YYYY-MM-DD
  final double systemOtHours;   // OT hệ thống (tự tính)
  final double requestedHours;  // OT đề nghị (người dùng nhập)
  final String reason;
  final OtRequestStatus status;
  final String? approverId;
  final String? rejectReason;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const OvertimeModel({
    required this.id,
    required this.userId,
    required this.date,
    this.systemOtHours = 0,
    this.requestedHours = 0,
    this.reason = '',
    this.status = OtRequestStatus.noOt,
    this.approverId,
    this.rejectReason,
    this.checkIn,
    this.checkOut,
  });

  bool get isEditable =>
    status == OtRequestStatus.noOt || status == OtRequestStatus.pending;
}

enum OtRequestStatus { noOt, pending, approved, rejected }

extension OtRequestStatusExt on OtRequestStatus {
  String get label {
    switch (this) {
      case OtRequestStatus.noOt: return 'Không có OT';
      case OtRequestStatus.pending: return 'Chờ duyệt';
      case OtRequestStatus.approved: return 'Đã duyệt';
      case OtRequestStatus.rejected: return 'Từ chối';
    }
  }
}
