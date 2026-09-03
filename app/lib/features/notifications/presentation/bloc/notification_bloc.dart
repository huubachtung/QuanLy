import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final MarkNotificationReadUseCase markRead;
  final MarkAllNotificationsReadUseCase markAllRead;

  NotificationBloc({
    required this.getNotifications,
    required this.markRead,
    required this.markAllRead,
  }) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadData);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  Future<void> _onLoadData(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (!event.isRefresh && state is! NotificationLoaded) {
      emit(NotificationLoading());
    }

    final failureOrData = await getNotifications(NoParams());
    failureOrData.fold(
      (failure) {
        if (state is! NotificationLoaded) {
          emit(NotificationError(failure.message));
        }
      },
      (data) {
        emit(NotificationLoaded(
          notifications: data.notifications,
          unreadCount: data.unreadCount,
        ));
      },
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final itemIndex = currentState.notifications.indexWhere((n) => n.id == event.id);
      if (itemIndex != -1) {
        final target = currentState.notifications[itemIndex];
        if (!target.isRead) {
          // Optimistic UI update
          final updatedList = List.of(currentState.notifications);
          updatedList[itemIndex] = target.copyWith(isRead: true);
          final updatedUnreadCount = max(0, currentState.unreadCount - 1);

          emit(NotificationLoaded(
            notifications: updatedList,
            unreadCount: updatedUnreadCount,
          ));
        }
      }

      // Background API call
      await markRead(event.id);
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      // Optimistic UI update
      final updatedList = currentState.notifications
          .map((n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList();

      emit(NotificationLoaded(
        notifications: updatedList,
        unreadCount: 0,
      ));

      // Background API call
      await markAllRead(NoParams());
    }
  }
}
