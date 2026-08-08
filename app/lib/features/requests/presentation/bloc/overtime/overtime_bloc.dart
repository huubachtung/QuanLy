import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/overtime_usecases.dart';
import 'overtime_event.dart';
import 'overtime_state.dart';

class OvertimeBloc extends Bloc<OvertimeEvent, OvertimeState> {
  final GetOvertimeDataUseCase getOvertime;
  final UpdateOvertimeRecordUseCase updateRecord;
  final MarkNoOtUseCase markNoOt;
  
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  OvertimeBloc({
    required this.getOvertime,
    required this.updateRecord,
    required this.markNoOt,
  }) : super(OvertimeInitial()) {
    on<LoadOvertimeData>(_onLoadData);
    on<UpdateOvertimeRecord>(_onUpdateRecord);
    on<MarkNoOt>(_onMarkNoOt);
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
    // Keep local update logic if needed, but for simplicity, we call remote then reload
    final currentState = state;
    if (currentState is OvertimeLoaded) {
      // Optimistic update omitted for simplicity, just await and reload
      final failureOrSuccess = await updateRecord(UpdateOvertimeParams(
        id: event.id, requestedHours: event.requestedHours, reason: event.reason
      ));
      
      failureOrSuccess.fold(
        (f) => emit(OvertimeError(f.message)),
        (_) {
          emit(const OvertimeActionSuccess('Cập nhật OT thành công'));
          add(LoadOvertimeData(month: currentMonth, year: currentYear));
        },
      );
    }
  }

  Future<void> _onMarkNoOt(MarkNoOt event, Emitter<OvertimeState> emit) async {
    if (state is OvertimeLoaded) {
      final failureOrSuccess = await markNoOt(event.id);
      failureOrSuccess.fold(
        (f) => emit(OvertimeError(f.message)),
        (_) {
          add(LoadOvertimeData(month: currentMonth, year: currentYear));
        },
      );
    }
  }
}
