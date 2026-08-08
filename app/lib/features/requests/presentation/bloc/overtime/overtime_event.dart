import 'package:equatable/equatable.dart';


abstract class OvertimeEvent extends Equatable {
  const OvertimeEvent();
  @override List<Object?> get props => [];
}

class LoadOvertimeData extends OvertimeEvent {
  final int month, year;
  const LoadOvertimeData({required this.month, required this.year});
  @override List<Object?> get props => [month, year];
}

class UpdateOvertimeRecord extends OvertimeEvent {
  final String id;
  final double requestedHours;
  final String reason;
  const UpdateOvertimeRecord({required this.id, required this.requestedHours, required this.reason});
  @override List<Object?> get props => [id, requestedHours, reason];
}

class MarkNoOt extends OvertimeEvent {
  final String id;
  const MarkNoOt(this.id);
  @override List<Object?> get props => [id];
}
