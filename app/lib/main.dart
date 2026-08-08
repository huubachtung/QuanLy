import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/router.dart';
import 'package:app/core/utils/theme.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/projects/presentation/bloc/projects_bloc.dart';
import 'features/projects/presentation/bloc/projects_event.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/attendance/presentation/bloc/attendance_event.dart';
import 'features/requests/presentation/bloc/leave/leave_bloc.dart';
import 'features/requests/presentation/bloc/leave/leave_event.dart';
import 'features/requests/presentation/bloc/overtime/overtime_bloc.dart';
import 'features/requests/presentation/bloc/overtime/overtime_event.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/assets/presentation/bloc/asset_bloc.dart';
import 'features/assets/presentation/bloc/asset_event.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize Dependency Injection
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const JussTVApp());
}

class JussTVApp extends StatelessWidget {
  const JussTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ProjectsBloc>()..add(LoadProjectsData())),
        BlocProvider(create: (_) => di.sl<AttendanceBloc>()..add(LoadAttendanceData(
          month: DateTime.now().month, year: DateTime.now().year))),
        BlocProvider(create: (_) => di.sl<LeaveBloc>()..add(LoadLeaveRequests())),
        BlocProvider(create: (_) => di.sl<OvertimeBloc>()..add(LoadOvertimeData(
          month: DateTime.now().month, year: DateTime.now().year))),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()..add(LoadNotifications())),
        BlocProvider(create: (_) => di.sl<AssetBloc>()..add(LoadAssets())),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            // Re-build router when AuthBloc state changes happens inside router now
            return Builder(
              builder: (ctx) {
                final authBloc = ctx.read<AuthBloc>();
                final router = buildRouter(authBloc);
                return MaterialApp.router(
                  title: 'Juss_TV',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeProvider.themeMode,
                  routerConfig: router,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.0),
                      ),
                      child: child!,
                    );
                  },
                );
              }
            );
          },
        ),
      ),
    );
  }
}
