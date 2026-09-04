import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

/// Background handler – PHẢI là hàm top-level (không nằm trong class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('🔔 [FCM Background] ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GoRouter? _router;
  ApiClient? _apiClient;
  bool _isInitialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Khởi tạo toàn bộ dịch vụ push notification
  Future<void> initialize({
    required GoRouter router,
    required ApiClient apiClient,
  }) async {
    if (_isInitialized) return;

    _router = router;
    _apiClient = apiClient;

    // 1. Xin quyền thông báo
    await _requestPermission();

    // 2. Cấu hình local notification channel (Android heads-up banner)
    await _setupLocalNotifications();

    // 3. Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Lắng nghe tin nhắn khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Lắng nghe khi user nhấn vào notification (app ở Background → mở lên)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Kiểm tra nếu app được mở từ notification khi đang terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
    debugPrint('✅ PushNotificationService initialized');
  }

  // ───────────────────────────────────────────────
  //  PUBLIC METHODS
  // ───────────────────────────────────────────────

  /// Lấy FCM device token hiện tại
  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Lỗi lấy FCM Token: $e');
      return null;
    }
  }

  /// Đăng ký token lên Backend (gọi khi login thành công)
  Future<void> registerTokenToServer() async {
    final token = await getDeviceToken();
    if (token == null || _apiClient == null) return;

    try {
      final device = Platform.isAndroid ? 'android' : 'ios';
      await _apiClient!.dio.post(
        '${ApiConstants.users}/fcm-token',
        data: {'token': token, 'device': device},
      );
      debugPrint('✅ FCM Token đã đăng ký lên server');
    } catch (e) {
      debugPrint('⚠️ Không thể đăng ký FCM Token: $e');
    }

    // Hủy subscription cũ nếu có để tránh duplicate listener
    await _tokenRefreshSub?.cancel();

    // Lắng nghe khi token bị refresh (Firebase tự động làm mới)
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        final device = Platform.isAndroid ? 'android' : 'ios';
        await _apiClient!.dio.post(
          '${ApiConstants.users}/fcm-token',
          data: {'token': newToken, 'device': device},
        );
        debugPrint('🔄 FCM Token đã được refresh và cập nhật lên server');
      } catch (e) {
        debugPrint('⚠️ Không thể cập nhật FCM Token mới: $e');
      }
    });
  }

  /// Hủy đăng ký token khỏi Backend (gọi khi logout)
  Future<void> unregisterTokenFromServer() async {
    // Hủy lắng nghe refresh token khi logout
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    try {
      final token = await _messaging.getToken();
      if (token != null && _apiClient != null) {
        await _apiClient!.dio.delete(
          '${ApiConstants.users}/fcm-token',
          data: {'token': token},
        );
      }
      await _messaging.deleteToken();
      debugPrint('✅ FCM Token đã được xóa khỏi server và thiết bị');
    } catch (e) {
      debugPrint('⚠️ Lỗi hủy FCM Token: $e');
    }
  }

  // ───────────────────────────────────────────────
  //  PRIVATE METHODS
  // ───────────────────────────────────────────────

  /// Xin quyền thông báo từ người dùng (iOS bắt buộc, Android 13+ cần)
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  /// Cấu hình Flutter Local Notifications cho Android heads-up banner
  Future<void> _setupLocalNotifications() async {
    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông Báo Quan Trọng',
      description: 'Kênh thông báo chính của ứng dụng Juss TV',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Tạo channel trên Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Cấu hình khởi tạo
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Đã xin qua FirebaseMessaging
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
  }

  /// Xử lý khi app đang mở mà nhận được push notification (Foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    // Hỗ trợ cả Notification payload lẫn Data-only payload
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    debugPrint('🔔 [Foreground] $title: $body');

    // Hiển thị banner heads-up qua Local Notification
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Thông Báo Quan Trọng',
          channelDescription: 'Kênh thông báo chính của ứng dụng Juss TV',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Truyền link vào payload để xử lý khi nhấn vào banner
      payload: message.data['link'],
    );
  }

  /// Xử lý khi user nhấn vào notification (app ở Background → mở lên)
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔗 [Opened App] data: ${message.data}');
    final rawLink = message.data['link'] as String?;
    if (rawLink != null && rawLink.trim().isNotEmpty && _router != null) {
      final link = rawLink.trim().startsWith('/') ? rawLink.trim() : '/${rawLink.trim()}';
      // Chờ frame render xong rồi mới navigate an toàn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _router!.go(link);
        } catch (e) {
          debugPrint('⚠️ Không thể điều hướng GoRouter đến $link: $e');
        }
      });
    }
  }

  /// Xử lý khi user nhấn vào local notification banner (Foreground case)
  void _onLocalNotificationTapped(NotificationResponse response) {
    final rawLink = response.payload;
    if (rawLink != null && rawLink.trim().isNotEmpty && _router != null) {
      final link = rawLink.trim().startsWith('/') ? rawLink.trim() : '/${rawLink.trim()}';
      try {
        _router!.go(link);
      } catch (e) {
        debugPrint('⚠️ Không thể điều hướng GoRouter đến $link: $e');
      }
    }
  }
}
