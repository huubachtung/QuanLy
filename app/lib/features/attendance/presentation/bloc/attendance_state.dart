import 'package:equatable/equatable.dart';
import '../../../../core/models/attendance_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {
  final int month;
  final int year;
  const AttendanceLoading(this.month, this.year);

  @override
  List<Object?> get props => [month, year];
}

class AttendanceLoaded extends AttendanceState {
  final AttendanceResponseModel response;
  final int selectedMonth;
  final int selectedYear;

  const AttendanceLoaded({
    required this.response,
    required this.selectedMonth,
    required this.selectedYear,
  });

  List<AttendanceModel> get records => response.records;

  List<AttendanceModel> get workDayRecords =>
      records.where((r) => r.status != AttendanceStatus.off).toList();

  AttendanceSummary get summary => response.summary;

  @override
  List<Object?> get props => [response, selectedMonth, selectedYear];

}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
