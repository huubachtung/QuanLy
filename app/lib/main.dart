import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app/router.dart';
import 'package:app/core/utils/theme.dart';
import 'injection_container.dart' as di;
import 'core/services/notification_polling_service.dart';
import 'core/models/notification_model.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/projects/presentation/bloc/projects_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/requests/presentation/bloc/leave/leave_bloc.dart';
import 'features/requests/presentation/bloc/overtime/overtime_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/notifications/presentation/bloc/notification_state.dart';
import 'features/assets/presentation/bloc/asset_bloc.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('vi', null);
  await di.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const JussTVApp());
}

class JussTVApp extends StatefulWidget {
  const JussTVApp({super.key});
  @override
  State<JussTVApp> createState() => _JussTVAppState();
}

class _JussTVAppState extends State<JussTVApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _dataLoaded = false;
  bool _localNotifInitialized = false;

  @override
  void initState() {
    super.initState();
    // Tạo AuthBloc và Router MỘT LẦN DUY NHẤT - tránh infinite rebuild
    _authBloc = di.sl<AuthBloc>()..add(AutoLoginRequested());
    _router = buildRouter(_authBloc);
  }

  @override
  void dispose() {
    NotificationPollingService.instance.stopPolling();
    _router.dispose();
    super.dispose();
  }

  /// Khởi tạo plugin thông báo cục bộ và tạo Android Channel
  Future<void> _initLocalNotifications() async {
    if (_localNotifInitialized) return;
    _localNotifInitialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationTap(payload);
        }
      },
    );

    // Tạo Notification Channel cho Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description:
              'Kênh thông báo quan trọng cho tác vụ, dự án và đơn từ.',
          importance: Importance.max,
        ),
      );
    }
  }

  /// Hiển thị banner thông báo cục bộ (Heads-up notification)
  Future<void> _showLocalNotificationBanner(NotificationModel item) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription:
          'Kênh thông báo quan trọng cho tác vụ, dự án và đơn từ.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notifId = item.id.hashCode;
    final payload = item.link.isNotEmpty ? item.link : '/notifications';

    await _localNotifications.show(
      notifId,
      item.title,
      item.body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Xử lý sự kiện người dùng chạm vào banner thông báo
  void _handleNotificationTap(String payload) {
    debugPrint('🔔 [MainApp] Người dùng chạm thông báo, payload: $payload');
    try {
      if (payload.startsWith('/')) {
        _router.push(payload);
      } else if (payload.isNotEmpty) {
        _router.push('/notifications');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi điều hướng thông báo: $e');
      _router.push('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => di.sl<ProjectsBloc>()),
        BlocProvider(create: (_) => di.sl<AttendanceBloc>()),
        BlocProvider(create: (_) => di.sl<LeaveBloc>()),
        BlocProvider(create: (_) => di.sl<OvertimeBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()),
        BlocProvider(create: (_) => di.sl<AssetBloc>()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) async {
                if (state is AuthAuthenticated) {
                  if (!_dataLoaded) {
                    _dataLoaded = true;

                    // 1. Khởi tạo Local Notifications (1 lần)
                    await _initLocalNotifications();

                    // 2. Nạp dữ liệu ban đầu (baseline)
                    if (context.mounted) {
                      context
                          .read<NotificationBloc>()
                          .add(const PollNotifications(isInitial: true));
                    }

                    // 3. Khởi động chu kỳ polling 5 phút / lần
                    NotificationPollingService.instance.startPolling(
                      onPollTick: () {
                        if (context.mounted) {
                          context
                              .read<NotificationBloc>()
                              .add(const PollNotifications());
                        }
                      },
                    );
                  }
                } else if (state is AuthUnauthenticated) {
                  if (_dataLoaded) {
                    // Dừng chu kỳ polling và reset BLoC
                    NotificationPollingService.instance.stopPolling();
                    if (context.mounted) {
                      context
                          .read<NotificationBloc>()
                          .add(ResetNotificationState());
                    }
                  }
                  _dataLoaded = false;
                }
              },
              child: BlocListener<NotificationBloc, NotificationState>(
                listener: (context, notifState) {
                  if (notifState is NotificationNewArrived) {
                    for (final item in notifState.newItems) {
                      _showLocalNotificationBanner(item);
                    }
                  }
                },
                child: MaterialApp.router(
                  title: 'Juss_TV',
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('vi', 'VN'),
                  supportedLocales: const [
                    Locale('vi', 'VN'),
                    Locale('en', 'US'),
                  ],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  routerConfig: _router,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
