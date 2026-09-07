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

  testWidgets('Test ProfilePage with pure UserEntity',
      (WidgetTester tester) async {
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

  testWidgets('Test ProfilePage when employeeType is null',
      (WidgetTester tester) async {
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

  testWidgets(
      'Test ProfilePage leave balances section adheres to design system',
      (WidgetTester tester) async {
    const userModel = UserModel(
      id: '123',
      username: 'tungns',
      displayName: 'Nguyễn Sơn Tùng',
      email: 'tungxxxx@gmail.com',
      role: 'member',
      employeeType: 'official',
      leaveBalances: [
        LeaveBalanceModel(
          leaveType: 'UNPAID_LEAVE',
          label: 'Nghỉ không lương',
          totalDays: 30,
          usedDays: 1,
        ),
        LeaveBalanceModel(
          leaveType: 'ANNUAL_LEAVE',
          label: 'Nghỉ phép năm',
          totalDays: 12,
          usedDays: 0,
        ),
        LeaveBalanceModel(
          leaveType: 'CONTRACEPTION_LEAVE',
          label: 'Nghỉ tránh thai',
          totalDays: 2,
          usedDays: 0,
        ),
        LeaveBalanceModel(
          leaveType: 'MILITARY_LEAVE',
          label: 'Nghỉ huấn luyện quân sự',
          totalDays: 0,
          usedDays: 0,
        ),
      ],
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

    expect(find.text('Hạn mức ngày phép'), findsOneWidget);
    expect(find.text('4 loại'), findsOneWidget);

    // Checks labels and subtitles
    expect(find.text('Nghỉ phép năm'), findsOneWidget);
    expect(find.text('Trừ phép tháng'), findsOneWidget);
    expect(find.text('Nghỉ không lương'), findsOneWidget);
    expect(find.text('Không trừ phép tháng'), findsNWidgets(3));

    // Checks badges
    expect(find.text('Sắp hết'), findsOneWidget);
    expect(find.text('Hết'), findsOneWidget);
    expect(find.text('Còn 29'), findsOneWidget);
  });
}
