import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String id;
  const MarkNotificationRead(this.id);
  @override List<Object?> get props => [id];
}

class MarkAllNotificationsRead extends NotificationEvent {}
