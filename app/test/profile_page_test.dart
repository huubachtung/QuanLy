import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Test ProfilePage with UserModel', (WidgetTester tester) async {
    const userModel = UserModel(
      id: '123',
      username: 'testuser',
      displayName: 'Nguyen Van Test Model',
      email: 'test@example.com',
      role: 'admin',
      employeeType: 'official',
    );

    final authBloc = MockAuthBloc(const AuthAuthenticated(userModel));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfilePage(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nguyen Van Test Model'), findsOneWidget);
  });

  testWidgets('Test ProfilePage with pure UserEntity', (WidgetTester tester) async {
    const userEntity = UserEntity(
      id: '123',
      username: 'testuser',
      displayName: 'Nguyen Van Test Entity',
      email: 'test@example.com',
      role: 'admin',
      employeeType: 'official',
    );

    final authBloc = MockAuthBloc(const AuthAuthenticated(userEntity));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfilePage(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nguyen Van Test Entity'), findsOneWidget);
  });

  testWidgets('Test ProfilePage when employeeType is null', (WidgetTester tester) async {
    const userEntity = UserEntity(
      id: '123',
      username: 'testuser',
      displayName: 'Nguyen Van Null EmployeeType',
      email: 'test@example.com',
      role: 'member',
      employeeType: null,
    );

    final authBloc = MockAuthBloc(const AuthAuthenticated(userEntity));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfilePage(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Nguyen Van Null EmployeeType'), findsOneWidget);
    expect(find.text('Chính thức'), findsWidgets);
  });
}
