import 'package:equatable/equatable.dart';

abstract class OvertimeEvent extends Equatable {
  const OvertimeEvent();
  @override
  List<Object?> get props => [];
}

class LoadOvertimeData extends OvertimeEvent {
  final int month, year;
  const LoadOvertimeData({required this.month, required this.year});
  @override
  List<Object?> get props => [month, year];
}

class UpdateOvertimeRecord extends OvertimeEvent {
  final String date;
  final double requestedHours;
  final String reason;
  const UpdateOvertimeRecord({
    required this.date,
    required this.requestedHours,
    required this.reason,
  });
  @override
  List<Object?> get props => [date, requestedHours, reason];
}

class MarkNoOt extends OvertimeEvent {
  final String date;
  const MarkNoOt(this.date);
  @override
  List<Object?> get props => [date];
}

class SubmitBulkOvertime extends OvertimeEvent {
  final List<Map<String, dynamic>> entries;
  const SubmitBulkOvertime(this.entries);
  @override
  List<Object?> get props => [entries];
}

class DeleteOvertimeRecord extends OvertimeEvent {
  final String id;
  const DeleteOvertimeRecord(this.id);
  @override
  List<Object?> get props => [id];
}
