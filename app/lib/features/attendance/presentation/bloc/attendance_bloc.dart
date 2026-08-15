import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_attendance.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceUseCase getAttendance;
  
  // Track currently selected so we don't lose it if error happens
  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  AttendanceBloc({required this.getAttendance}) : super(AttendanceInitial()) {
    on<LoadAttendanceData>(_onLoadAttendanceData);
  }

  Future<void> _onLoadAttendanceData(LoadAttendanceData event, Emitter<AttendanceState> emit) async {
    currentMonth = event.month;
    currentYear = event.year;
    
    emit(AttendanceLoading(event.month, event.year));
    final failureOrData = await getAttendance(GetAttendanceParams(month: event.month, year: event.year));
    
    failureOrData.fold(
      (failure) => emit(AttendanceError(failure.message)),
      (data) => emit(AttendanceLoaded(
        response: data,
        selectedMonth: event.month,
        selectedYear: event.year,
      )),
    );
  }
}
