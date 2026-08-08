import 'package:equatable/equatable.dart';
import 'package:app/core/models/leave_request_model.dart';

abstract class LeaveEvent extends Equatable {
  const LeaveEvent();
  @override List<Object?> get props => [];
}

class LoadLeaveRequests extends LeaveEvent {}

class CreateLeaveRequest extends LeaveEvent {
  final LeaveRequestModel request;
  const CreateLeaveRequest(this.request);
  @override List<Object?> get props => [request];
}

class CancelLeaveRequest extends LeaveEvent {
  final String id;
  const CancelLeaveRequest(this.id);
  @override List<Object?> get props => [id];
}
