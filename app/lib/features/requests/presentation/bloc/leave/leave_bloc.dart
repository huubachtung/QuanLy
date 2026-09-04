import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/core/usecases/usecase.dart';
import '../../../domain/usecases/leave_usecases.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final GetLeaveRequestsUseCase getRequests;
  final CreateLeaveRequestUseCase createReq;
  final CancelLeaveRequestUseCase cancelReq;

  LeaveBloc({
    required this.getRequests,
    required this.createReq,
    required this.cancelReq,
  }) : super(LeaveInitial()) {
    on<LoadLeaveRequests>(_onLoadRequests);
    on<CreateLeaveRequest>(_onCreateRequest);
    on<CancelLeaveRequest>(_onCancelRequest);
  }

  Future<void> _onLoadRequests(LoadLeaveRequests event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final failureOrData = await getRequests(NoParams());
    failureOrData.fold(
      (f) => emit(LeaveError(f.message)),
      (data) => emit(LeaveLoaded(
        requests: data.requests,
        annualLeaveBalance: data.annualLeaveBalance,
        annualMaxDays: data.annualMaxDays,
        pendingDeducts: data.pendingDeducts,
        stats: data.stats,
      )),
    );
  }

  Future<void> _onCreateRequest(CreateLeaveRequest event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final failureOrSuccess = await createReq(event.request);
    failureOrSuccess.fold(
      (f) => emit(LeaveError(f.message)),
      (_) {
        emit(const LeaveActionSuccess('Gửi yêu cầu thành công'));
        add(LoadLeaveRequests()); // reload
      },
    );
  }

  Future<void> _onCancelRequest(CancelLeaveRequest event, Emitter<LeaveState> emit) async {
    emit(LeaveLoading());
    final failureOrSuccess = await cancelReq(event.id);
    failureOrSuccess.fold(
      (f) => emit(LeaveError(f.message)),
      (success) {
        if (success) {
          emit(const LeaveActionSuccess('Đã huỷ yêu cầu'));
        } else {
          emit(const LeaveError('Không thể huỷ yêu cầu này'));
        }
        add(LoadLeaveRequests()); // reload
      },
    );
  }
}
