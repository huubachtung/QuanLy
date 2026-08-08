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
  final List<AttendanceModel> records;
  final int selectedMonth;
  final int selectedYear;

  const AttendanceLoaded({
    required this.records,
    required this.selectedMonth,
    required this.selectedYear,
  });

  List<AttendanceModel> get workDayRecords =>
      records.where((r) => r.status != AttendanceStatus.off).toList();

  AttendanceSummary get summary {
    final work = workDayRecords.where((r) =>
      r.status != AttendanceStatus.absent && r.checkIn != null).toList();
    return AttendanceSummary(
      workDays: work.length,
      totalNormalHours: work.fold(0, (s, r) => s + r.normalHours),
      approvedOtHours: records.where((r) => r.otStatus == OtStatus.approved).fold(0, (s, r) => s + r.overtimeHours),
      pendingOtHours: records.where((r) => r.otStatus == OtStatus.pending).fold(0, (s, r) => s + r.overtimeHours),
      rejectedOtHours: records.where((r) => r.otStatus == OtStatus.rejected).fold(0, (s, r) => s + r.overtimeHours),
      totalCong: records.fold(0, (s, r) => s + r.dailyCong),
      totalOtHours: records.where((r) => r.otStatus == OtStatus.approved).fold(0, (s, r) => s + r.overtimeHours),
    );
  }

  @override
  List<Object?> get props => [records, selectedMonth, selectedYear];
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
