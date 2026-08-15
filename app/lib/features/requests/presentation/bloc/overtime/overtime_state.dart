import 'package:equatable/equatable.dart';
import 'package:app/core/models/overtime_model.dart';

abstract class OvertimeState extends Equatable {
  const OvertimeState();
  @override
  List<Object?> get props => [];
}

class OvertimeInitial extends OvertimeState {}

class OvertimeLoading extends OvertimeState {
  final int month, year;
  const OvertimeLoading(this.month, this.year);
  @override
  List<Object?> get props => [month, year];
}

class OvertimeLoaded extends OvertimeState {
  final List<OvertimeModel> records;
  final int selectedMonth, selectedYear;
  final bool isSubmitting;

  const OvertimeLoaded({
    required this.records,
    required this.selectedMonth,
    required this.selectedYear,
    this.isSubmitting = false,
  });

  double get totalCalculatedHours =>
      records.fold<double>(0.0, (s, r) => s + r.calculatedOtHours);

  double get totalRequestedHours =>
      records.fold<double>(0.0, (s, r) => s + r.requestedOtHours);

  double get totalApprovedHours => records
      .where((r) => r.status == OtStatus.approved)
      .fold<double>(0.0, (s, r) => s + r.requestedOtHours);

  List<OvertimeModel> get submittableRecords => records
      .where((r) => r.isEditable && r.requestedOtHours > 0)
      .toList();

  List<OvertimeModel> get pendingRecords => records
      .where((r) => r.status == OtStatus.pending && r.requestedOtHours > 0)
      .toList();

  OvertimeLoaded copyWith({
    List<OvertimeModel>? records,
    int? selectedMonth,
    int? selectedYear,
    bool? isSubmitting,
  }) {
    return OvertimeLoaded(
      records: records ?? this.records,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [records, selectedMonth, selectedYear, isSubmitting];
}

class OvertimeError extends OvertimeState {
  final String message;
  const OvertimeError(this.message);
  @override
  List<Object?> get props => [message];
}

class OvertimeActionSuccess extends OvertimeState {
  final String message;
  const OvertimeActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
