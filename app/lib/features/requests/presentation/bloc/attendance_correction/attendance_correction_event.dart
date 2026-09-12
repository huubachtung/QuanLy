import 'package:equatable/equatable.dart';

abstract class AttendanceCorrectionEvent extends Equatable {
  const AttendanceCorrectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceCorrections extends AttendanceCorrectionEvent {
  final int? month;
  final int? year;
  final String? status;

  const LoadAttendanceCorrections({
    this.month,
    this.year,
    this.status,
  });

  @override
  List<Object?> get props => [month, year, status];
}

class CreateAttendanceCorrectionRequested extends AttendanceCorrectionEvent {
  final String userId;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String reason;

  const CreateAttendanceCorrectionRequested({
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, date, timeIn, timeOut, reason];
}

class DeleteAttendanceCorrectionRequested extends AttendanceCorrectionEvent {
  final String id;

  const DeleteAttendanceCorrectionRequested(this.id);

  @override
  List<Object?> get props => [id];
}
