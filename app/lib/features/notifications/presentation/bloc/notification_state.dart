import 'package:equatable/equatable.dart';
import '../../../../core/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  List<NotificationModel> byFilter(String filter) {
    if (filter == 'all') return notifications;
    if (filter == 'unread') return notifications.where((n) => !n.isRead).toList();
    return notifications.where((n) => n.type.filterKey == filter).toList();
  }

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount];
}

/// State phát ra khi chu kỳ polling phát hiện có thông báo mới chưa đọc.
/// Kế thừa [NotificationLoaded] để UI vẫn hiển thị danh sách và badge bình thường,
/// đồng thời [BlocListener] trong main.dart có thể bắt được để kích hoạt Local Notification banner.
class NotificationNewArrived extends NotificationLoaded {
  final List<NotificationModel> newItems;

  const NotificationNewArrived({
    required this.newItems,
    required super.notifications,
    required super.unreadCount,
  });

  @override
  List<Object?> get props => [newItems, notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}
