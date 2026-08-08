import 'package:equatable/equatable.dart';
import '../../../../core/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  const NotificationLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<NotificationModel> byFilter(String filter) {
    if (filter == 'all') return notifications;
    if (filter == 'unread') return notifications.where((n) => !n.isRead).toList();
    return notifications.where((n) => n.type.filterKey == filter).toList();
  }

  @override List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override List<Object?> get props => [message];
}
