import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_correction.dart';

abstract class AttendanceCorrectionState extends Equatable {
  const AttendanceCorrectionState();

  @override
  List<Object?> get props => [];
}

class AttendanceCorrectionInitial extends AttendanceCorrectionState {}

class AttendanceCorrectionLoading extends AttendanceCorrectionState {}

class AttendanceCorrectionLoaded extends AttendanceCorrectionState {
  final List<AttendanceCorrection> requests;
  final int selectedMonth;
  final int selectedYear;
  final String selectedStatus;

  const AttendanceCorrectionLoaded({
    required this.requests,
    required this.selectedMonth,
    required this.selectedYear,
    this.selectedStatus = 'ALL',
  });

  List<AttendanceCorrection> get filteredRequests {
    if (selectedStatus == 'ALL') return requests;
    final target = AttendanceCorrectionStatusExt.fromString(selectedStatus);
    return requests.where((r) => r.status == target).toList();
  }

  @override
  List<Object?> get props => [
        requests,
        selectedMonth,
        selectedYear,
        selectedStatus,
      ];
}

class AttendanceCorrectionActionSuccess extends AttendanceCorrectionState {
  final String message;

  const AttendanceCorrectionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceCorrectionError extends AttendanceCorrectionState {
  final String message;

  const AttendanceCorrectionError(this.message);

  @override
  List<Object?> get props => [message];
}
