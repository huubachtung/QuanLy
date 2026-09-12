import 'package:equatable/equatable.dart';

enum AttendanceCorrectionStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

extension AttendanceCorrectionStatusExt on AttendanceCorrectionStatus {
  String get value {
    switch (this) {
      case AttendanceCorrectionStatus.pending:
        return 'PENDING';
      case AttendanceCorrectionStatus.approved:
        return 'APPROVED';
      case AttendanceCorrectionStatus.rejected:
        return 'REJECTED';
      case AttendanceCorrectionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case AttendanceCorrectionStatus.pending:
        return 'Chờ duyệt';
      case AttendanceCorrectionStatus.approved:
        return 'Đã duyệt';
      case AttendanceCorrectionStatus.rejected:
        return 'Từ chối';
      case AttendanceCorrectionStatus.cancelled:
        return 'Đã huỷ';
    }
  }

  static AttendanceCorrectionStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'APPROVED':
        return AttendanceCorrectionStatus.approved;
      case 'REJECTED':
        return AttendanceCorrectionStatus.rejected;
      case 'CANCELLED':
        return AttendanceCorrectionStatus.cancelled;
      case 'PENDING':
      default:
        return AttendanceCorrectionStatus.pending;
    }
  }
}

class AttendanceCorrection extends Equatable {
  final String id;
  final String userId;
  final String? creatorId;
  final String date; // YYYY-MM-DD
  final String? timeIn; // HH:mm
  final String? timeOut; // HH:mm
  final String reason;
  final AttendanceCorrectionStatus status;
  final String? approverId;
  final String? approverName;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceCorrection({
    required this.id,
    required this.userId,
    this.creatorId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
    required this.status,
    this.approverId,
    this.approverName,
    this.approvedAt,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        creatorId,
        date,
        timeIn,
        timeOut,
        reason,
        status,
        approverId,
        approverName,
        approvedAt,
        createdAt,
        updatedAt,
      ];
}
