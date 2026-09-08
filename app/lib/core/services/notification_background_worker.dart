import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/api_constants.dart';

/// Top-level callback dispatcher cho WorkManager (chạy trong Isolate nền độc lập)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('🔔 [BackgroundWorker] ========================================');
      debugPrint('🔔 [BackgroundWorker] Bắt đầu thực thi background task: $taskName');
      WidgetsFlutterBinding.ensureInitialized();

      const storage = FlutterSecureStorage();

      // 1. Gọi fetchNotificationsWithRetry để lấy danh sách thông báo (tự động refresh token nếu cần)
      final notificationsList = await NotificationBackgroundWorker.fetchNotificationsWithRetry(
        storage: storage,
      );

      if (notificationsList == null) {
        debugPrint('🔔 [BackgroundWorker] Không có dữ liệu thông báo hoặc chưa đăng nhập. Hoàn thành task.');
        return Future.value(true);
      }

      // 2. Đọc danh sách ID đã biết từ local storage
      final knownIdsRaw = await storage.read(key: NotificationBackgroundWorker.storageKnownIdsKey);
      Set<String> knownIds = {};
      if (knownIdsRaw != null && knownIdsRaw.isNotEmpty) {
        try {
          final list = jsonDecode(knownIdsRaw) as List<dynamic>;
          knownIds = list.map((e) => e.toString()).toSet();
        } catch (e) {
          debugPrint('⚠️ [BackgroundWorker] Lỗi giải mã knownIds cache: $e');
        }
      }

      final fetchedIds = notificationsList
          .map((item) => item is Map<String, dynamic> ? (item['_id'] ?? item['id'] ?? '').toString() : '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Nếu lần đầu tiên background chạy và chưa có baseline
      if (knownIds.isEmpty) {
        debugPrint('🔔 [BackgroundWorker] Thiết lập baseline (${fetchedIds.length} IDs), không bắn banner');
        await storage.write(
          key: NotificationBackgroundWorker.storageKnownIdsKey,
          value: jsonEncode(fetchedIds.toList()),
        );
        return Future.value(true);
      }

      // 3. Tìm các thông báo mới chưa đọc
      final newUnreadItems = notificationsList.where((item) {
        if (item is! Map<String, dynamic>) return false;
        final id = (item['_id'] ?? item['id'] ?? '').toString();
        final isRead = item['isRead'] == true;
        return id.isNotEmpty && !knownIds.contains(id) && !isRead;
      }).toList();

      if (newUnreadItems.isNotEmpty) {
        debugPrint('🔔 [BackgroundWorker] Phát hiện ${newUnreadItems.length} thông báo mới trong nền!');

        // Khởi tạo Local Notifications Plugin an toàn cho cả iOS và Android
        try {
          final localNotif = FlutterLocalNotificationsPlugin();
          const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
          const darwinInit = DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
          const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);
          await localNotif.initialize(initSettings);

          const androidDetails = AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Kênh thông báo quan trọng cho tác vụ, dự án và đơn từ.',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          );
          const darwinDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
          const notifDetails = NotificationDetails(
            android: androidDetails,
            iOS: darwinDetails,
          );

          for (final item in newUnreadItems) {
            final id = (item['_id'] ?? item['id'] ?? '').toString();
            final title = (item['title'] ?? 'Thông Báo Mới').toString();
            final body = (item['body'] ?? '').toString();
            final link = (item['link'] ?? '/notifications').toString();

            debugPrint('🔔 [BackgroundWorker] Hiển thị banner cho thông báo id: $id, title: $title');
            await localNotif.show(
              id.hashCode,
              title,
              body,
              notifDetails,
              payload: link.isNotEmpty ? link : '/notifications',
            );
          }
        } catch (notifErr, notifStack) {
          debugPrint('⚠️ [BackgroundWorker] Lỗi khi hiển thị banner notification (không gây crash): $notifErr\n$notifStack');
        }

        // Cập nhật knownIds
        knownIds.addAll(fetchedIds);
        await storage.write(
          key: NotificationBackgroundWorker.storageKnownIdsKey,
          value: jsonEncode(knownIds.take(300).toList()),
        );
      } else {
        debugPrint('🔔 [BackgroundWorker] Không có thông báo mới cần cảnh báo.');
        // Đồng bộ các ID đã fetch
        if (fetchedIds.isNotEmpty) {
          knownIds.addAll(fetchedIds);
          await storage.write(
            key: NotificationBackgroundWorker.storageKnownIdsKey,
            value: jsonEncode(knownIds.take(300).toList()),
          );
        }
      }

      debugPrint('🔔 [BackgroundWorker] Hoàn thành background task: $taskName thành công.');
      debugPrint('🔔 [BackgroundWorker] ========================================');
      return Future.value(true);
    } catch (e, stack) {
      debugPrint('⚠️ [BackgroundWorker] Ngoại lệ tổng thể khi xử lý background task (an toàn, không crash): $e\n$stack');
      return Future.value(true);
    }
  });
}

/// Quản lý đăng ký và cấu hình WorkManager cho ứng dụng
class NotificationBackgroundWorker {
  static const String periodicTaskUniqueName = 'com.jusstv.QuanLy.periodicNotificationPoll';
  static const String periodicTaskName = 'periodicNotificationPoll';
  static const String storageKnownIdsKey = 'bg_known_notification_ids';

  static bool _isInitialized = false;

  /// Lấy danh sách thông báo từ API trong background với cơ chế tự động refresh token nếu gặp 401.
  /// Trả về danh sách notifications (List<dynamic>) nếu thành công, hoặc null nếu thất bại / chưa đăng nhập.
  /// Hỗ trợ dependency injection [dioClient], [refreshDioClient], [storage] để phục vụ kiểm thử đơn vị.
  static Future<List<dynamic>?> fetchNotificationsWithRetry({
    FlutterSecureStorage? storage,
    Dio? dioClient,
    Dio? refreshDioClient,
  }) async {
    final secStorage = storage ?? const FlutterSecureStorage();

    try {
      final accessToken = await secStorage.read(key: 'access_token');
      if (accessToken == null || accessToken.trim().isEmpty) {
        debugPrint('🔔 [BackgroundWorker] Không tìm thấy access_token trong storage, dừng tác vụ.');
        return null;
      }
      debugPrint('🔔 [BackgroundWorker] Đã tìm thấy access_token (độ dài: ${accessToken.length}), bắt đầu gọi API.');

      final client = dioClient ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Accept': 'application/json',
              },
            ),
          );

      // Đảm bảo client có Authorization header nếu được truyền qua DI
      client.options.headers['Authorization'] = 'Bearer $accessToken';

      Response? response;
      bool needsRefresh = false;

      try {
        debugPrint('🔔 [BackgroundWorker] Đang gửi GET ${ApiConstants.notifications} ...');
        response = await client.get(ApiConstants.notifications);
        if (response.statusCode == 401) {
          needsRefresh = true;
        }
      } on DioException catch (dioErr) {
        debugPrint('⚠️ [BackgroundWorker] Lỗi DioException khi gọi notifications: status=${dioErr.response?.statusCode}, type=${dioErr.type}');
        if (dioErr.response?.statusCode == 401) {
          needsRefresh = true;
        } else {
          return null;
        }
      } catch (e) {
        debugPrint('⚠️ [BackgroundWorker] Ngoại lệ không mong muốn khi fetch notifications: $e');
        return null;
      }

      // Nếu gặp mã lỗi 401 Unauthorized -> Thực hiện làm mới token
      if (needsRefresh) {
        debugPrint('🔄 [BackgroundWorker] Nhận HTTP 401 Unauthorized -> Bắt đầu quy trình làm mới token trong Isolate nền...');
        final newAccessToken = await attemptRefreshToken(
          storage: secStorage,
          refreshDio: refreshDioClient,
        );

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          debugPrint('✅ [BackgroundWorker] Refresh token thành công! Đang retry request lấy thông báo...');
          try {
            client.options.headers['Authorization'] = 'Bearer $newAccessToken';
            response = await client.get(ApiConstants.notifications);
            debugPrint('✅ [BackgroundWorker] Retry thành công với HTTP status: ${response.statusCode}');
          } on DioException catch (retryDioErr) {
            debugPrint('❌ [BackgroundWorker] Retry thất bại sau khi refresh token: status=${retryDioErr.response?.statusCode}');
            return null;
          } catch (retryErr) {
            debugPrint('❌ [BackgroundWorker] Lỗi không xác định khi retry request: $retryErr');
            return null;
          }
        } else {
          debugPrint('❌ [BackgroundWorker] Không thể làm mới token (hết hạn hoặc lỗi mạng), dừng tác vụ nền.');
          return null;
        }
      }

      if (response == null || response.statusCode != 200 || response.data == null) {
        debugPrint('⚠️ [BackgroundWorker] HTTP status không hợp lệ hoặc response null: ${response?.statusCode}');
        return null;
      }

      final data = response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        debugPrint('⚠️ [BackgroundWorker] Response body không thành công (success != true)');
        return null;
      }

      final notificationsList = data['notifications'] as List<dynamic>? ?? [];
      debugPrint('🔔 [BackgroundWorker] Lấy thành công ${notificationsList.length} thông báo từ server.');
      return notificationsList;
    } catch (e, stack) {
      debugPrint('⚠️ [BackgroundWorker] Ngoại lệ trong fetchNotificationsWithRetry (an toàn): $e\n$stack');
      return null;
    }
  }

  /// Thực hiện gọi endpoint làm mới token từ [storage]
  /// Trả về newAccessToken nếu thành công, hoặc null nếu thất bại
  static Future<String?> attemptRefreshToken({
    FlutterSecureStorage? storage,
    Dio? refreshDio,
  }) async {
    final secStorage = storage ?? const FlutterSecureStorage();
    try {
      final refreshToken = await secStorage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        debugPrint('⚠️ [BackgroundWorker] Không tìm thấy refresh_token trong SecureStorage để làm mới.');
        return null;
      }

      debugPrint('🔄 [BackgroundWorker] Đang gửi POST ${ApiConstants.refreshToken} ...');
      final client = refreshDio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

      final refreshResponse = await client.post(
        ApiConstants.refreshToken,
        data: {
          'refreshToken': refreshToken,
          'refresh_token': refreshToken,
        },
      );

      debugPrint('🔄 [BackgroundWorker] Kết quả refresh token: HTTP ${refreshResponse.statusCode}');
      if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
        final data = refreshResponse.data;
        if (data is Map<String, dynamic>) {
          // Hỗ trợ cả trường hợp token nằm ở root hoặc nằm trong trường 'data'
          Map<String, dynamic> tokenMap = data;
          if (data['data'] is Map<String, dynamic>) {
            tokenMap = data['data'] as Map<String, dynamic>;
          }

          final newAccessToken = (tokenMap['accessToken'] ??
                  tokenMap['access_token'] ??
                  data['accessToken'] ??
                  data['access_token'])
              ?.toString();
          final newRefreshToken = (tokenMap['refreshToken'] ??
                  tokenMap['refresh_token'] ??
                  data['refreshToken'] ??
                  data['refresh_token'])
              ?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            debugPrint('💾 [BackgroundWorker] Đang lưu access_token mới vào SecureStorage...');
            await secStorage.write(key: 'access_token', value: newAccessToken);

            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              debugPrint('💾 [BackgroundWorker] Đang lưu refresh_token mới vào SecureStorage...');
              await secStorage.write(key: 'refresh_token', value: newRefreshToken);
            }

            debugPrint('✅ [BackgroundWorker] Đã cập nhật token mới vào SecureStorage thành công.');
            return newAccessToken;
          }
        }
      }
      debugPrint('⚠️ [BackgroundWorker] Response refresh token không chứa access_token hợp lệ.');
    } on DioException catch (dioErr) {
      debugPrint('❌ [BackgroundWorker] DioException khi refresh token: status=${dioErr.response?.statusCode}');
    } catch (e, stack) {
      debugPrint('❌ [BackgroundWorker] Ngoại lệ không xác định khi refresh token: $e\n$stack');
    }
    return null;
  }

  /// Khởi tạo WorkManager (gọi trong main() trước runApp())
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );
      _isInitialized = true;
      debugPrint('🔔 [BackgroundWorker] Đã khởi tạo WorkManager thành công.');
    } catch (e) {
      debugPrint('⚠️ [BackgroundWorker] Không thể khởi tạo WorkManager: $e');
    }
  }

  /// Đăng ký Periodic Task (15 phút / lần) khi người dùng đăng nhập
  /// Hỗ trợ cả Android và iOS ổn định không gây crash
  static Future<void> registerPeriodicTask() async {
    try {
      bool isAndroid = false;
      try {
        isAndroid = Platform.isAndroid;
      } catch (_) {}

      if (isAndroid) {
        await Workmanager().registerPeriodicTask(
          periodicTaskUniqueName,
          periodicTaskName,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
          initialDelay: const Duration(minutes: 15),
        );
        debugPrint('🔔 [BackgroundWorker] Đã lên lịch Periodic Task trên Android (15 phút / lần)');
      } else {
        debugPrint('🔔 [BackgroundWorker] Trên iOS, background task được quản lý bởi BGTaskScheduler.');
      }
    } catch (e) {
      debugPrint('⚠️ [BackgroundWorker] Lỗi đăng ký Periodic Task (an toàn, không crash): $e');
    }
  }

  /// Hủy Periodic Task khi đăng xuất
  static Future<void> cancelPeriodicTask() async {
    try {
      bool isAndroid = false;
      try {
        isAndroid = Platform.isAndroid;
      } catch (_) {}

      if (isAndroid) {
        await Workmanager().cancelByUniqueName(periodicTaskUniqueName);
        debugPrint('🔔 [BackgroundWorker] Đã hủy Periodic Task.');
      }
    } catch (e) {
      debugPrint('⚠️ [BackgroundWorker] Lỗi hủy Periodic Task (an toàn, không crash): $e');
    }
  }

  /// Đồng bộ danh sách IDs đã biết từ Foreground BLoC vào SecureStorage
  static Future<void> syncKnownIds(Set<String> ids) async {
    try {
      const storage = FlutterSecureStorage();
      await storage.write(
        key: storageKnownIdsKey,
        value: jsonEncode(ids.take(300).toList()),
      );
    } catch (e) {
      debugPrint('⚠️ [BackgroundWorker] Không thể đồng bộ knownIds: $e');
    }
  }

  /// Xóa cache danh sách IDs đã biết khi đăng xuất
  static Future<void> clearKnownIds() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: storageKnownIdsKey);
    } catch (e) {
      debugPrint('⚠️ [BackgroundWorker] Lỗi xóa cache knownIds: $e');
    }
  }
}
