import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceData extends AttendanceEvent {
  final int month;
  final int year;

  const LoadAttendanceData({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}
