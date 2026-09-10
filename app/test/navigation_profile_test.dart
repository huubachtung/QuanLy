import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:app/features/home/presentation/bloc/home_bloc.dart';
import 'package:app/features/home/presentation/pages/home_page.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationBloc extends Bloc<NotificationEvent, NotificationState>
    implements NotificationBloc {
  MockNotificationBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Full flow: navigate to profile and pop back',
      (WidgetTester tester) async {
    const userEntity = UserEntity(
      id: 'mock_user_id_123',
      username: 'testuser',
      displayName: 'Nguyen Van Test',
      email: 'testuser@example.com',
      role: 'admin',
      employeeType: 'official',
      annualLeaveBalance: 12,
      employeeCode: 'EMP001',
    );

    final authBloc = MockAuthBloc(const AuthAuthenticated(userEntity));
    final notifBloc = MockNotificationBloc(NotificationInitial());

    final router = GoRouter(
      initialLocation: '/requests',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(
            body: ProfilePage(),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => BlocProvider(
            create: (_) => HomeBloc(),
            child: HomePage(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/projects',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Projects Screen Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Calendar Screen Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/notifications',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Notifications Screen Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/attendance',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Attendance Screen Content')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/requests',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Requests Screen Content')),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<NotificationBloc>.value(value: notifBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/requests');

    final profileButton = find.byType(CircleAvatar);
    await tester.tap(profileButton);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/profile');

    final error = tester.takeException();
    expect(error, isNull);
  });
}
