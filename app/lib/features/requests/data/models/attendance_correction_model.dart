import '../../domain/entities/attendance_correction.dart';

class AttendanceCorrectionModel extends AttendanceCorrection {
  const AttendanceCorrectionModel({
    required super.id,
    required super.userId,
    super.creatorId,
    required super.date,
    super.timeIn,
    super.timeOut,
    required super.reason,
    required super.status,
    super.approverId,
    super.approverName,
    super.approvedAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory AttendanceCorrectionModel.fromJson(Map<String, dynamic> json) {
    String parseDate(dynamic d) {
      if (d == null) return '';
      final str = d.toString();
      if (str.length >= 10) {
        return str.substring(0, 10);
      }
      return str;
    }

    DateTime parseDateTime(dynamic dt) {
      if (dt == null) return DateTime.now();
      if (dt is DateTime) return dt;
      try {
        return DateTime.parse(dt.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }

    String? approverName;
    if (json['approver'] is Map<String, dynamic>) {
      final app = json['approver'] as Map<String, dynamic>;
      approverName = app['displayName'] ?? app['username'] ?? app['name'];
    } else if (json['approverName'] != null) {
      approverName = json['approverName']?.toString();
    }

    return AttendanceCorrectionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      creatorId: json['creatorId']?.toString(),
      date: parseDate(json['date']),
      timeIn: json['timeIn']?.toString(),
      timeOut: json['timeOut']?.toString(),
      reason: json['reason']?.toString() ?? '',
      status: AttendanceCorrectionStatusExt.fromString(json['status']?.toString()),
      approverId: json['approverId']?.toString(),
      approverName: approverName,
      approvedAt: json['approvedAt'] != null ? parseDateTime(json['approvedAt']) : null,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date,
      if (timeIn != null && timeIn!.isNotEmpty) 'timeIn': timeIn,
      if (timeOut != null && timeOut!.isNotEmpty) 'timeOut': timeOut,
      'reason': reason,
    };
  }

  AttendanceCorrection toEntity() => this;
}
