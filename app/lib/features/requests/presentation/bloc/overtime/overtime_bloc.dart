import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/overtime_usecases.dart';
import 'overtime_event.dart';
import 'overtime_state.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final GetOvertimeDataUseCase getOvertime;
  final UpdateOvertimeRecordUseCase updateRecord;
  final MarkNoOtUseCase markNoOt;
  final SubmitBulkOvertimeUseCase submitBulk;
  final DeleteOvertimeRecordUseCase deleteRecord;

  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  OvertimeBloc({
    required this.getOvertime,
    required this.updateRecord,
    required this.markNoOt,
    required this.submitBulk,
    required this.deleteRecord,
  }) : super(OvertimeInitial()) {
    on<LoadOvertimeData>(_onLoadData);
    on<UpdateOvertimeRecord>(_onUpdateRecord);
    on<MarkNoOt>(_onMarkNoOt);
    on<SubmitBulkOvertime>(_onSubmitBulk);
    on<DeleteOvertimeRecord>(_onDeleteRecord);
  }

  Future<void> _onLoadData(LoadOvertimeData event, Emitter<OvertimeState> emit) async {
    currentMonth = event.month;
    currentYear = event.year;

    emit(OvertimeLoading(event.month, event.year));
    final failureOrData = await getOvertime(GetOvertimeParams(month: event.month, year: event.year));

    failureOrData.fold(
      (f) => emit(OvertimeError(f.message)),
      (data) => emit(OvertimeLoaded(
        records: data,
        selectedMonth: event.month,
        selectedYear: event.year,
      )),
    );
  }

  Future<void> _onUpdateRecord(UpdateOvertimeRecord event, Emitter<OvertimeState> emit) async {
    final failureOrSuccess = await updateRecord(UpdateOvertimeParams(
      date: event.date,
      requestedHours: event.requestedHours,
      reason: event.reason,
    ));

    failureOrSuccess.fold(
      (f) => emit(OvertimeError(f.message)),
      (_) {
        emit(OvertimeActionSuccess('Đã lưu yêu cầu OT ngày ${event.date}'));
        add(LoadOvertimeData(month: currentMonth, year: currentYear));
      },
    );
  }

  Future<void> _onMarkNoOt(MarkNoOt event, Emitter<OvertimeState> emit) async {
    final failureOrSuccess = await markNoOt(event.date);
    failureOrSuccess.fold(
      (f) => emit(OvertimeError(f.message)),
      (_) {
        emit(OvertimeActionSuccess('Đã xác nhận không OT ngày ${event.date}'));
        add(LoadOvertimeData(month: currentMonth, year: currentYear));
      },
    );
  }

  Future<void> _onSubmitBulk(SubmitBulkOvertime event, Emitter<OvertimeState> emit) async {
    final currentState = state;
    if (currentState is OvertimeLoaded) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    final failureOrMsg = await submitBulk(event.entries);
    failureOrMsg.fold(
      (f) {
        if (currentState is OvertimeLoaded) {
          emit(currentState.copyWith(isSubmitting: false));
        }
        emit(OvertimeError(f.message));
      },
      (msg) {
        emit(OvertimeActionSuccess(msg));
        add(LoadOvertimeData(month: currentMonth, year: currentYear));
      },
    );
  }

  Future<void> _onDeleteRecord(DeleteOvertimeRecord event, Emitter<OvertimeState> emit) async {
    final failureOrSuccess = await deleteRecord(event.id);
    failureOrSuccess.fold(
      (f) => emit(OvertimeError(f.message)),
      (_) {
        emit(const OvertimeActionSuccess('Đã xóa yêu cầu OT'));
        add(LoadOvertimeData(month: currentMonth, year: currentYear));
      },
    );
  }
}
