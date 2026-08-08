import 'package:equatable/equatable.dart';
import 'package:app/core/models/overtime_model.dart';

abstract class OvertimeState extends Equatable {
  const OvertimeState();
  @override List<Object?> get props => [];
}

class OvertimeInitial extends OvertimeState {}

class OvertimeLoading extends OvertimeState {
  final int month, year;
  const OvertimeLoading(this.month, this.year);
  @override List<Object?> get props => [month, year];
}

class OvertimeLoaded extends OvertimeState {
  final List<OvertimeModel> records;
  final int selectedMonth, selectedYear;

  const OvertimeLoaded({
    required this.records,
    required this.selectedMonth,
    required this.selectedYear,
  });

  double get totalRequestedHours =>
      records.fold(0, (s, r) => s + r.requestedHours);

  List<OvertimeModel> get pendingRecords =>
      records.where((r) => r.status == OtRequestStatus.pending && r.requestedHours > 0).toList();

  @override List<Object?> get props => [records, selectedMonth, selectedYear];
}

class OvertimeError extends OvertimeState {
  final String message;
  const OvertimeError(this.message);
  @override List<Object?> get props => [message];
}

class OvertimeActionSuccess extends OvertimeState {
  final String message;
  const OvertimeActionSuccess(this.message);
  @override List<Object?> get props => [message];
}
