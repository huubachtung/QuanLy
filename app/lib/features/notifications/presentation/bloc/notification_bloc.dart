import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_background_worker.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotifications;
  final MarkNotificationReadUseCase markRead;
  final MarkAllNotificationsReadUseCase markAllRead;

  final Set<String> _knownNotificationIds = {};
  bool _baselineLoaded = false;

  NotificationBloc({
    required this.getNotifications,
    required this.markRead,
    required this.markAllRead,
  }) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadData);
    on<PollNotifications>(_onPoll);
    on<ResetNotificationState>(_onReset);
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
        _knownNotificationIds.addAll(data.notifications.map((n) => n.id));
        _baselineLoaded = true;
        NotificationBackgroundWorker.syncKnownIds(_knownNotificationIds);

        emit(NotificationLoaded(
          notifications: data.notifications,
          unreadCount: data.unreadCount,
        ));
      },
    );
  }

  Future<void> _onPoll(
    PollNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    debugPrint('🔔 [NotificationBloc] Bắt đầu polling thông báo...');
    final failureOrData = await getNotifications(NoParams());
    failureOrData.fold(
      (failure) {
        debugPrint('🔔 [NotificationBloc] Polling thất bại: ${failure.message}');
      },
      (data) {
        final fetchedNotifications = data.notifications;
        final fetchedIds = fetchedNotifications.map((n) => n.id).toSet();

        if (event.isInitial || !_baselineLoaded) {
          // Lần đầu tải (baseline): ghi nhận tất cả ID hiện có, không bắn banner
          _knownNotificationIds
            ..clear()
            ..addAll(fetchedIds);
          _baselineLoaded = true;
          NotificationBackgroundWorker.syncKnownIds(_knownNotificationIds);

          debugPrint(
            '🔔 [NotificationBloc] Baseline nạp xong: ${_knownNotificationIds.length} thông báo, unread: ${data.unreadCount}',
          );

          emit(NotificationLoaded(
            notifications: fetchedNotifications,
            unreadCount: data.unreadCount,
          ));
          return;
        }

        // Các chu kỳ polling tiếp theo: diff tìm thông báo mới chưa đọc
        final newItems = fetchedNotifications
            .where((n) => !_knownNotificationIds.contains(n.id) && !n.isRead)
            .toList();

        // Cập nhật tập ID đã biết
        _knownNotificationIds.addAll(fetchedIds);
        NotificationBackgroundWorker.syncKnownIds(_knownNotificationIds);

        if (newItems.isNotEmpty) {
          debugPrint('🔔 [NotificationBloc] Phát hiện ${newItems.length} thông báo mới!');
          emit(NotificationNewArrived(
            newItems: newItems,
            notifications: fetchedNotifications,
            unreadCount: data.unreadCount,
          ));
        } else {
          emit(NotificationLoaded(
            notifications: fetchedNotifications,
            unreadCount: data.unreadCount,
          ));
        }
      },
    );
  }

  void _onReset(
    ResetNotificationState event,
    Emitter<NotificationState> emit,
  ) {
    debugPrint('🔔 [NotificationBloc] Reset trạng thái thông báo');
    _knownNotificationIds.clear();
    _baselineLoaded = false;
    NotificationBackgroundWorker.clearKnownIds();
    emit(NotificationInitial());
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
