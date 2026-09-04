import 'package:equatable/equatable.dart';
import 'package:app/core/models/leave_request_model.dart';

abstract class LeaveState extends Equatable {
  const LeaveState();
  @override List<Object?> get props => [];
}

class LeaveInitial extends LeaveState {}

class LeaveLoading extends LeaveState {}

class LeaveLoaded extends LeaveState {
  final List<LeaveRequestModel> requests;
  final double annualLeaveBalance;
  final double annualMaxDays;
  final double pendingDeducts;
  final Map<String, LeaveStatItem> stats;

  const LeaveLoaded({
    required this.requests,
    this.annualLeaveBalance = 12.0,
    this.annualMaxDays = 12.0,
    this.pendingDeducts = 0.0,
    this.stats = const {},
  });

  List<LeaveRequestModel> byStatus(RequestStatus? status) {
    if (status == null) return requests;
    return requests.where((r) => r.status == status).toList();
  }

  List<LeaveRequestModel> byType(String type) {
    if (type == 'all') return requests;
    if (type == 'leave') {
      return requests.where((r) => !r.leaveType.isSpecialRequest).toList();
    }
    if (type == 'special') {
      return requests.where((r) => r.leaveType.isSpecialRequest).toList();
    }
    return requests;
  }

  @override
  List<Object?> get props => [
        requests,
        annualLeaveBalance,
        annualMaxDays,
        pendingDeducts,
        stats,
      ];
}

class LeaveError extends LeaveState {
  final String message;
  const LeaveError(this.message);
  @override List<Object?> get props => [message];
}

class LeaveActionSuccess extends LeaveState {
  final String message;
  const LeaveActionSuccess(this.message);
  @override List<Object?> get props => [message];
}
