import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/attendance_correction_usecases.dart';
import 'attendance_correction_event.dart';
import 'attendance_correction_state.dart';

class AttendanceCorrectionBloc
    extends Bloc<AttendanceCorrectionEvent, AttendanceCorrectionState> {
  final GetAttendanceCorrectionsUseCase getCorrections;
  final CreateAttendanceCorrectionUseCase createCorrection;
  final DeleteAttendanceCorrectionUseCase deleteCorrection;

  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  String _currentStatus = 'ALL';

  AttendanceCorrectionBloc({
    required this.getCorrections,
    required this.createCorrection,
    required this.deleteCorrection,
  }) : super(AttendanceCorrectionInitial()) {
    on<LoadAttendanceCorrections>(_onLoad);
    on<CreateAttendanceCorrectionRequested>(_onCreate);
    on<DeleteAttendanceCorrectionRequested>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAttendanceCorrections event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    _currentMonth = event.month ?? _currentMonth;
    _currentYear = event.year ?? _currentYear;
    _currentStatus = event.status ?? _currentStatus;

    emit(AttendanceCorrectionLoading());

    final result = await getCorrections(GetAttendanceCorrectionParams(
      month: _currentMonth,
      year: _currentYear,
      status: _currentStatus,
    ));

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (items) => emit(AttendanceCorrectionLoaded(
        requests: items,
        selectedMonth: _currentMonth,
        selectedYear: _currentYear,
        selectedStatus: _currentStatus,
      )),
    );
  }

  Future<void> _onCreate(
    CreateAttendanceCorrectionRequested event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    emit(AttendanceCorrectionLoading());

    final result = await createCorrection(CreateAttendanceCorrectionParams(
      userId: event.userId,
      date: event.date,
      timeIn: event.timeIn,
      timeOut: event.timeOut,
      reason: event.reason,
    ));

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (_) {
        emit(const AttendanceCorrectionActionSuccess(
            'Gửi yêu cầu chấm công lại thành công'));
        add(LoadAttendanceCorrections(
          month: _currentMonth,
          year: _currentYear,
          status: _currentStatus,
        ));
      },
    );
  }

  Future<void> _onDelete(
    DeleteAttendanceCorrectionRequested event,
    Emitter<AttendanceCorrectionState> emit,
  ) async {
    emit(AttendanceCorrectionLoading());

    final result = await deleteCorrection(event.id);

    result.fold(
      (failure) => emit(AttendanceCorrectionError(failure.message)),
      (success) {
        if (success) {
          emit(const AttendanceCorrectionActionSuccess('Đã huỷ yêu cầu thành công'));
        } else {
          emit(const AttendanceCorrectionError('Không thể huỷ yêu cầu này'));
        }
        add(LoadAttendanceCorrections(
          month: _currentMonth,
          year: _currentYear,
          status: _currentStatus,
        ));
      },
    );
  }
}
