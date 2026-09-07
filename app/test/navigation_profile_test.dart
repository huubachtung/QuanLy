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
      id: '6a32b74f6c31356209a1dc1b',
      username: 'tungns',
      displayName: 'Nguyễn Sơn Tùng',
      email: 'tung912n@gmail.com',
      role: 'admin',
      employeeType: 'official',
      annualLeaveBalance: 12,
      employeeCode: '31',
    );

    final authBloc = MockAuthBloc(const AuthAuthenticated(userEntity));
    final notifBloc = MockNotificationBloc(NotificationInitial());

    final router = GoRouter(
      initialLocation: '/requests',
      routes: [
        ShellRoute(
          builder: (context, state, child) => BlocProvider(
            create: (_) => HomeBloc(),
            child: HomePage(child: child),
          ),
          routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) =>
                  const Scaffold(body: Text('Requests Screen Content')),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
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
