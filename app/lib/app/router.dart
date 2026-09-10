import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../injection_container.dart';
import '../core/providers/theme_provider.dart';
import '../core/utils/app_colors.dart';
import '../core/utils/app_tokens.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/projects/presentation/pages/project_list_page.dart';
import '../features/projects/presentation/pages/task_list_page.dart';
import '../features/projects/presentation/pages/timeline_page.dart';
import '../features/projects/presentation/pages/project_detail_page.dart';
import '../features/projects/presentation/pages/task_detail_page.dart';
import '../features/projects/presentation/pages/project_calendar_page.dart';
import '../features/notifications/presentation/pages/notification_page.dart';
import '../features/attendance/presentation/pages/attendance_page.dart';
import '../features/requests/presentation/pages/leave_request_page.dart';
import '../features/requests/presentation/pages/overtime_page.dart';
import '../features/requests/presentation/pages/request_list_page.dart';
import '../features/assets/presentation/pages/asset_page.dart';
import '../features/assets/presentation/pages/asset_detail_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/projects',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final isAuth = authBloc.state is AuthAuthenticated;
      final isLogin = state.matchedLocation == '/login';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/projects';
      if (state.matchedLocation == '/') return '/projects';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, st) => const LoginPage()),
      GoRoute(
        path: '/profile',
        builder: (ctx, st) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hồ sơ cá nhân'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Quay lại',
                onPressed: () {
                  if (ctx.canPop()) {
                    ctx.pop();
                  } else {
                    ctx.go('/projects');
                  }
                },
              ),
              actions: [
                Consumer<ThemeProvider>(
                  builder: (_, tp, __) => IconButton(
                    onPressed: tp.toggleTheme,
                    icon: Icon(
                      tp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: isDark ? AppColors.gold : AppColors.primaryBlue,
                      size: AppTokens.iconAction,
                    ),
                    tooltip: tp.isDark ? 'Chế độ sáng' : 'Chế độ tối',
                  ),
                ),
                const SizedBox(width: AppTokens.s4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            body: const ProfilePage(),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (ctx, st, navigationShell) => BlocProvider(
          create: (_) => sl<HomeBloc>(),
          child: HomePage(navigationShell: navigationShell),
        ),
        branches: [
          // Branch 0: Dự án
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/projects', builder: (ctx, st) => const ProjectListPage()),
              GoRoute(path: '/tasks', builder: (ctx, st) => const TaskListPage()),
              GoRoute(path: '/timeline', builder: (ctx, st) => const TimelinePage()),
              GoRoute(
                path: '/projects/:id',
                builder: (ctx, st) => ProjectDetailPage(projectId: st.pathParameters['id']!),
              ),
              GoRoute(
                path: '/project/:id',
                builder: (ctx, st) => ProjectDetailPage(projectId: st.pathParameters['id']!),
              ),
              GoRoute(
                path: '/tasks/:id',
                builder: (ctx, st) => TaskDetailPage(taskId: st.pathParameters['id']!),
              ),
              GoRoute(
                path: '/task/:id',
                builder: (ctx, st) => TaskDetailPage(taskId: st.pathParameters['id']!),
              ),
              GoRoute(path: '/assets', builder: (ctx, st) => const AssetPage()),
              GoRoute(
                path: '/assets/:id',
                builder: (ctx, st) => AssetDetailPage(assetId: st.pathParameters['id']!),
              ),
            ],
          ),
          // Branch 1: Lịch
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/calendar', builder: (ctx, st) => const ProjectCalendarPage()),
            ],
          ),
          // Branch 2: Thông báo
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/notifications', builder: (ctx, st) => const NotificationPage()),
            ],
          ),
          // Branch 3: Chấm công
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/attendance', builder: (ctx, st) => const AttendancePage()),
            ],
          ),
          // Branch 4: Yêu cầu
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/requests', builder: (ctx, st) => const RequestListPage()),
              GoRoute(path: '/leave', builder: (ctx, st) => const LeaveRequestPage()),
              GoRoute(path: '/overtime', builder: (ctx, st) => const OvertimePage()),
            ],
          ),
        ],
      ),
    ],
  );
}
