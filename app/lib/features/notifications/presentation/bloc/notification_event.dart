import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final bool isRefresh;
  const LoadNotifications({this.isRefresh = false});
  @override
  List<Object?> get props => [isRefresh];
}

class PollNotifications extends NotificationEvent {
  final bool isInitial;
  const PollNotifications({this.isInitial = false});
  @override
  List<Object?> get props => [isInitial];
}

class ResetNotificationState extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String id;
  const MarkNotificationRead(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsRead extends NotificationEvent {}
