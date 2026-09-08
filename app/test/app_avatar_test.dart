import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/core/widgets/app_avatar.dart';
import 'package:app/features/auth/data/models/user_model.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import 'package:app/features/profile/presentation/pages/profile_page.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MockAuthBlocForAvatar extends Bloc<AuthEvent, AuthState>
    implements AuthBloc {
  MockAuthBlocForAvatar(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppAvatar URL & Initials Resolution Tests', () {
    test('resolveAvatarUrl: null and empty', () {
      expect(AppAvatar.resolveAvatarUrl(null), isNull);
      expect(AppAvatar.resolveAvatarUrl(''), isNull);
      expect(AppAvatar.resolveAvatarUrl('   '), isNull);
      expect(AppAvatar.resolveAvatarUrl('null'), isNull);
      expect(AppAvatar.resolveAvatarUrl('undefined'), isNull);
    });

    test('resolveAvatarUrl: Absolute HTTP/HTTPS URLs', () {
      const url = 'https://example.com/demo/image/upload/sample.jpg';
      expect(AppAvatar.resolveAvatarUrl(url), url);
    });

    test('resolveAvatarUrl: Protocol-relative URL', () {
      const url = '//example.com/demo/image/upload/sample.jpg';
      expect(AppAvatar.resolveAvatarUrl(url), 'https:$url');
    });

    test('resolveAvatarUrl: Relative path starting with /', () {
      const relative = '/uploads/avatars/avatar1.png';
      expect(AppAvatar.resolveAvatarUrl(relative),
          'https://chaos.io.vn/uploads/avatars/avatar1.png');
    });

    test('resolveAvatarUrl: Relative path without /', () {
      const relative = 'uploads/avatars/avatar2.png';
      expect(AppAvatar.resolveAvatarUrl(relative),
          'https://chaos.io.vn/uploads/avatars/avatar2.png');
    });

    test('resolveAvatarUrl: JSON Cloudinary object string', () {
      const jsonStr =
          '{"url": "https://example.com/demo/image/sample.jpg", "public_id": "123"}';
      expect(AppAvatar.resolveAvatarUrl(jsonStr),
          'https://example.com/demo/image/sample.jpg');
    });

    test('resolveAvatarUrl: Data URI', () {
      const dataUri = 'data:image/svg+xml;utf8,<svg></svg>';
      expect(AppAvatar.resolveAvatarUrl(dataUri), dataUri);
    });

    test('isSvg detection', () {
      expect(
          AppAvatar.isSvg('https://api.dicebear.com/7.x/bottts/svg?seed=Felix'),
          isTrue);
      expect(AppAvatar.isSvg('https://example.com/user.svg'), isTrue);
      expect(AppAvatar.isSvg('https://example.com/user.svg?v=1.0'), isTrue);
      expect(AppAvatar.isSvg('data:image/svg+xml;utf8,<svg></svg>'), isTrue);
      expect(AppAvatar.isSvg('https://example.com/user.png'), isFalse);
      expect(AppAvatar.isSvg('https://example.com/user.jpg'), isFalse);
    });

    test('getInitials logic', () {
      expect(AppAvatar.getInitials('Nguyen Test'), 'NT');
      expect(AppAvatar.getInitials('testuser'), 'TE');
      expect(AppAvatar.getInitials('T'), 'T');
      expect(AppAvatar.getInitials(''), 'NV');
      expect(AppAvatar.getInitials(null), 'NV');
    });
  });

  group('UserModel parsing mock data', () {
    test('Correctly parses userId object from mock data', () {
      final json = {
        "_id": "mock_user_id_123",
        "username": "testuser",
        "department": {
          "_id": "mock_dept_id_123",
          "name": "Phong Ban Test",
        },
        "displayName": "Nguyen Van Test",
        "email": "testuser@example.com",
        "annualLeaveBalance": 12,
        "employeeCode": "EMP001",
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'mock_user_id_123');
      expect(user.username, 'testuser');
      expect(user.displayName, 'Nguyen Van Test');
      expect(user.email, 'testuser@example.com');
      expect(user.employeeCode, 'EMP001');
      expect(user.annualLeaveBalance, 12.0);
      expect(user.departmentId, 'mock_dept_id_123');
    });

    test('Correctly parses leaveBalances from mock data', () {
      final json = {
        "_id": "mock_user_id_123",
        "username": "testuser",
        "displayName": "Nguyen Van Test",
        "email": "testuser@example.com",
        "role": "member",
        "leaveBalances": [
          {
            "leaveType": "ANNUAL_LEAVE",
            "totalDays": 12,
            "daysPerMonth": 0,
            "usedDays": 0,
            "_id": "mock_leave_id_1"
          },
          {
            "leaveType": "UNPAID_LEAVE",
            "totalDays": 30,
            "daysPerMonth": 0,
            "usedDays": 1,
            "_id": "mock_leave_id_2"
          }
        ]
      };

      final user = UserModel.fromJson(json);

      expect(user.leaveBalances.length, 2);
      expect(user.leaveBalances[0].leaveType, 'ANNUAL_LEAVE');
      expect(user.leaveBalances[0].label, 'Nghỉ phép năm');
      expect(user.leaveBalances[0].totalDays, 12.0);
      expect(user.leaveBalances[0].usedDays, 0.0);
      expect(user.leaveBalances[0].remainingDays, 12.0);

      expect(user.leaveBalances[1].leaveType, 'UNPAID_LEAVE');
      expect(user.leaveBalances[1].label, 'Nghỉ không lương');
      expect(user.leaveBalances[1].totalDays, 30.0);
      expect(user.leaveBalances[1].usedDays, 1.0);
      expect(user.leaveBalances[1].remainingDays, 29.0);
    });
  });

  group('ProfilePage with Mock Data Rendering', () {
    testWidgets('ProfilePage displays accurate fields from mock user',
        (WidgetTester tester) async {
      final user = UserModel.fromJson(const {
        "_id": "mock_user_id_123",
        "username": "testuser",
        "department": "mock_dept_id_123",
        "displayName": "Nguyen Van Test",
        "email": "testuser@example.com",
        "annualLeaveBalance": 12,
        "employeeCode": "EMP001",
        "role": "member",
        "leaveBalances": [
          {
            "leaveType": "ANNUAL_LEAVE",
            "totalDays": 12,
            "daysPerMonth": 0,
            "usedDays": 0,
            "_id": "mock_leave_id_1"
          }
        ]
      });

      final authBloc = MockAuthBlocForAvatar(AuthAuthenticated(user));

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

      expect(find.text('Nguyen Van Test'), findsOneWidget);
      expect(find.text('Mã NV: EMP001'), findsOneWidget);
      expect(find.text('testuser@example.com'), findsOneWidget);
      expect(find.text('12 ngày'), findsOneWidget);
      expect(find.text('Hạn mức ngày phép'), findsOneWidget);
      expect(find.text('Nghỉ phép năm'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });
}
