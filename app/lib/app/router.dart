import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../injection_container.dart';
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
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final isAuth = authBloc.state is AuthAuthenticated;
      final isLogin = state.matchedLocation == '/login';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, st) => const LoginPage()),
      ShellRoute(
        builder: (ctx, st, child) => BlocProvider(
          create: (_) => sl<HomeBloc>(),
          child: HomePage(child: child),
        ),
        routes: [
          GoRoute(path: '/', builder: (ctx, st) => const ProjectListPage()),
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
          GoRoute(path: '/calendar', builder: (ctx, st) => const ProjectCalendarPage()),
          GoRoute(path: '/notifications', builder: (ctx, st) => const NotificationPage()),
          GoRoute(path: '/attendance', builder: (ctx, st) => const AttendancePage()),
          GoRoute(path: '/leave', builder: (ctx, st) => const LeaveRequestPage()),
          GoRoute(path: '/overtime', builder: (ctx, st) => const OvertimePage()),
          GoRoute(path: '/requests', builder: (ctx, st) => const RequestListPage()),
          GoRoute(path: '/assets', builder: (ctx, st) => const AssetPage()),
          GoRoute(
            path: '/assets/:id',
            builder: (ctx, st) => AssetDetailPage(assetId: st.pathParameters['id']!),
          ),
          GoRoute(path: '/profile', builder: (ctx, st) => const ProfilePage()),
        ],
      ),
    ],
  );
}
