import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/router.dart';
import 'package:app/core/utils/theme.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/projects/presentation/bloc/projects_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/requests/presentation/bloc/leave/leave_bloc.dart';
import 'features/requests/presentation/bloc/overtime/overtime_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
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
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Tạo AuthBloc và Router MỘT LẦN DUY NHẤT - tránh infinite rebuild
    _authBloc = di.sl<AuthBloc>()..add(AutoLoginRequested());
    _router = buildRouter(_authBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
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
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  if (!_dataLoaded) {
                    _dataLoaded = true;
                    context.read<NotificationBloc>().add(const LoadNotifications());
                  }
                } else if (state is AuthUnauthenticated) {
                  _dataLoaded = false;
                }
              },
              child: MaterialApp.router(
                title: 'Juss_TV',
                debugShowCheckedModeBanner: false,
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
            );
          },
        ),
      ),
    );
  }
}
