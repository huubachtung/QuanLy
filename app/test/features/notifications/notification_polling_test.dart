import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/models/notification_model.dart';
import 'package:app/core/services/notification_polling_service.dart';
import 'package:app/core/services/notification_background_worker.dart';
import 'package:app/core/constants/api_constants.dart';
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
    recipientId: 'user_dummy_1',
    type: NotificationType.system,
    title: title,
    body: 'Body of $title',
    isRead: isRead,
    createdAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

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
      final notif1 = _createNotification(id: 'notif_dummy_1', title: 'Thông báo 1');
      final notif2 = _createNotification(id: 'notif_dummy_2', title: 'Thông báo 2');

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
      final notif1 = _createNotification(id: 'notif_dummy_1', title: 'Thông báo 1');
      fakeRepo.result = NotificationListResult(
        notifications: [notif1],
        unreadCount: 1,
      );

      // 1. Initial baseline
      bloc.add(const PollNotifications(isInitial: true));
      await Future.delayed(const Duration(milliseconds: 50));

      // 2. New notification arrives
      final notif2 = _createNotification(id: 'notif_dummy_2', title: 'Thông báo 2 Mới', isRead: false);
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
      expect(newArrivedState.newItems.first.id, 'notif_dummy_2');
    });

    test('Subsequent poll without new items does not emit NotificationNewArrived', () async {
      final notif1 = _createNotification(id: 'notif_dummy_1', title: 'Thông báo 1');
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
      final notif1 = _createNotification(id: 'notif_dummy_1', title: 'Thông báo 1');
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

  group('NotificationBackgroundWorker Token Refresh & Robustness', () {
    const storage = FlutterSecureStorage();

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Case 1: Direct fetch success (HTTP 200 OK) returns notification list', () async {
      await storage.write(key: 'access_token', value: 'mock_token_abc_123');

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Authorization'], 'Bearer mock_token_abc_123');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'notifications': [
                    {
                      '_id': 'notif_dummy_001',
                      'title': 'Test Notification 1',
                      'body': 'Test content 1',
                      'isRead': false,
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final result = await NotificationBackgroundWorker.fetchNotificationsWithRetry(
        storage: storage,
        dioClient: dio,
      );

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first['_id'], 'notif_dummy_001');
    });

    test('Case 2: 401 on initial fetch -> Refresh token succeeds -> Retry fetch succeeds', () async {
      await storage.write(key: 'access_token', value: 'mock_expired_token_000');
      await storage.write(key: 'refresh_token', value: 'mock_refresh_token_valid');

      int notificationsCallCount = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            notificationsCallCount++;
            if (notificationsCallCount == 1) {
              // Lần 1: Trả về 401 Unauthorized
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 401,
                    data: {'message': 'Token expired'},
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            } else {
              // Lần 2 (Retry): Yêu cầu dùng token mới
              expect(options.headers['Authorization'], 'Bearer mock_new_access_token_111');
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'notifications': [
                      {
                        '_id': 'notif_dummy_002',
                        'title': 'Test Notification 2',
                        'body': 'Retry succeeded content',
                        'isRead': false,
                      }
                    ],
                  },
                ),
              );
            }
          },
        ),
      );

      final refreshDio = Dio();
      refreshDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, contains(ApiConstants.refreshToken));
            expect(options.data['refreshToken'], 'mock_refresh_token_valid');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'mock_new_access_token_111',
                  'refreshToken': 'mock_new_refresh_token_222',
                },
              ),
            );
          },
        ),
      );

      final result = await NotificationBackgroundWorker.fetchNotificationsWithRetry(
        storage: storage,
        dioClient: dio,
        refreshDioClient: refreshDio,
      );

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first['_id'], 'notif_dummy_002');
      expect(notificationsCallCount, 2);

      // Xác nhận token mới đã được ghi đè vào SecureStorage
      expect(await storage.read(key: 'access_token'), 'mock_new_access_token_111');
      expect(await storage.read(key: 'refresh_token'), 'mock_new_refresh_token_222');
    });

    test('Case 3: 401 on initial fetch -> Refresh token fails -> Returns null without crash', () async {
      await storage.write(key: 'access_token', value: 'mock_expired_token_000');
      await storage.write(key: 'refresh_token', value: 'mock_expired_refresh_token');

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final refreshDio = Dio();
      refreshDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Invalid refresh token'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final result = await NotificationBackgroundWorker.fetchNotificationsWithRetry(
        storage: storage,
        dioClient: dio,
        refreshDioClient: refreshDio,
      );

      expect(result, isNull);
    });

    test('Case 4: Missing access_token returns null immediately', () async {
      // Storage rỗng
      final result = await NotificationBackgroundWorker.fetchNotificationsWithRetry(
        storage: storage,
      );
      expect(result, isNull);
    });

    test('Case 5: syncKnownIds and clearKnownIds work properly with storage', () async {
      await NotificationBackgroundWorker.syncKnownIds({'notif_a', 'notif_b'});
      final raw = await storage.read(key: NotificationBackgroundWorker.storageKnownIdsKey);
      expect(raw, contains('notif_a'));
      expect(raw, contains('notif_b'));

      await NotificationBackgroundWorker.clearKnownIds();
      final cleared = await storage.read(key: NotificationBackgroundWorker.storageKnownIdsKey);
      expect(cleared, isNull);
    });

    test('Case 6: Lifecycle helpers (initialize, registerPeriodicTask, cancelPeriodicTask) execute safely', () async {
      // Đảm bảo không ném exception / crash kể cả trên mock/test runtime
      await NotificationBackgroundWorker.initialize();
      await NotificationBackgroundWorker.registerPeriodicTask();
      await NotificationBackgroundWorker.cancelPeriodicTask();
    });
  });
}
