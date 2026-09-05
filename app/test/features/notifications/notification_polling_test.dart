import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/models/notification_model.dart';
import 'package:app/core/services/notification_polling_service.dart';
import 'package:app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:app/features/notifications/presentation/bloc/notification_state.dart';

class FakeNotificationRepository implements NotificationRepository {
  NotificationListResult result = const NotificationListResult(
    notifications: [],
    unreadCount: 0,
  );

  @override
  Future<Either<Failure, NotificationListResult>> getNotifications() async {
    return Right(result);
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    return const Right(null);
  }
}

NotificationModel _createNotification({
  required String id,
  required String title,
  bool isRead = false,
}) {
  return NotificationModel(
    id: id,
    recipientId: 'user_1',
    type: NotificationType.system,
    title: title,
    body: 'Body of $title',
    isRead: isRead,
    createdAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPollingService', () {
    test('singleton instance exists', () {
      expect(NotificationPollingService.instance, isNotNull);
    });

    test('startPolling and stopPolling manage state without crash', () {
      final service = NotificationPollingService.instance;
      int tickCount = 0;

      service.startPolling(onPollTick: () {
        tickCount++;
      });

      expect(tickCount, 0);

      service.stopPolling();
    });
  });

  group('NotificationBloc Polling & Baseline', () {
    late FakeNotificationRepository fakeRepo;
    late NotificationBloc bloc;

    setUp(() {
      fakeRepo = FakeNotificationRepository();
      bloc = NotificationBloc(
        getNotifications: GetNotificationsUseCase(fakeRepo),
        markRead: MarkNotificationReadUseCase(fakeRepo),
        markAllRead: MarkAllNotificationsReadUseCase(fakeRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial poll sets baseline without emitting NotificationNewArrived', () async {
      final notif1 = _createNotification(id: 'n1', title: 'Thông báo 1');
      final notif2 = _createNotification(id: 'n2', title: 'Thông báo 2');

      fakeRepo.result = NotificationListResult(
        notifications: [notif1, notif2],
        unreadCount: 2,
      );

      final states = <NotificationState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PollNotifications(isInitial: true));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 1);
      expect(states.first, isA<NotificationLoaded>());
      expect(states.first is NotificationNewArrived, isFalse);
      expect((states.first as NotificationLoaded).notifications.length, 2);
    });

    test('Subsequent poll with new unread items emits NotificationNewArrived', () async {
      final notif1 = _createNotification(id: 'n1', title: 'Thông báo 1');
      fakeRepo.result = NotificationListResult(
        notifications: [notif1],
        unreadCount: 1,
      );

      // 1. Initial baseline
      bloc.add(const PollNotifications(isInitial: true));
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. New notification arrives
      final notif2 = _createNotification(id: 'n2', title: 'Thông báo 2 Mới', isRead: false);
      fakeRepo.result = NotificationListResult(
        notifications: [notif2, notif1],
        unreadCount: 2,
      );

      final states = <NotificationState>[];
      bloc.stream.listen(states.add);

      // Subsequent tick
      bloc.add(const PollNotifications(isInitial: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s is NotificationNewArrived), isTrue);
      final newArrivedState = states.firstWhere((s) => s is NotificationNewArrived) as NotificationNewArrived;
      expect(newArrivedState.newItems.length, 1);
      expect(newArrivedState.newItems.first.id, 'n2');
    });

    test('Subsequent poll without new items does not emit NotificationNewArrived', () async {
      final notif1 = _createNotification(id: 'n1', title: 'Thông báo 1');
      fakeRepo.result = NotificationListResult(
        notifications: [notif1],
        unreadCount: 1,
      );

      // Baseline
      bloc.add(const PollNotifications(isInitial: true));
      await Future.delayed(const Duration(milliseconds: 50));

      // Poll again with same data
      final states = <NotificationState>[];
      bloc.stream.listen(states.add);

      bloc.add(const PollNotifications(isInitial: false));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.any((s) => s is NotificationNewArrived), isFalse);
    });

    test('ResetNotificationState clears baseline and returns to NotificationInitial', () async {
      final notif1 = _createNotification(id: 'n1', title: 'Thông báo 1');
      fakeRepo.result = NotificationListResult(
        notifications: [notif1],
        unreadCount: 1,
      );

      bloc.add(const PollNotifications(isInitial: true));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<NotificationLoaded>());

      bloc.add(ResetNotificationState());
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<NotificationInitial>());
    });
  });
}
