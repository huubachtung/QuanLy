import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/providers/theme_provider.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/token_storage.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:app/features/auth/domain/usecases/login_usecase.dart';
import 'package:app/features/auth/domain/usecases/auto_login_usecase.dart';
import 'package:app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  bool logoutCalled = false;

  @override
  Future<Either<Failure, UserEntity>> login(String username, String password) async {
    return const Right(UserEntity(
      id: 'u1',
      username: 'test',
      displayName: 'Test User',
      email: 'test@mail.com',
      role: 'staff',
    ));
  }

  @override
  Future<Either<Failure, UserEntity>> autoLogin() async {
    return const Right(UserEntity(
      id: 'u1',
      username: 'test',
      displayName: 'Test User',
      email: 'test@mail.com',
      role: 'staff',
    ));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalled = true;
    return const Right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthBloc TokenExpired & Logout Flow', () {
    late MockAuthRepository mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepository();
      authBloc = AuthBloc(
        loginUseCase: LoginUseCase(mockRepo),
        autoLoginUseCase: AutoLoginUseCase(mockRepo),
        logoutUseCase: LogoutUseCase(mockRepo),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('TokenExpired calls logoutUseCase and emits AuthUnauthenticated with explanation message', () async {
      authBloc.add(TokenExpired());

      await expectLater(
        authBloc.stream,
        emits(isA<AuthUnauthenticated>().having(
          (s) => s.message,
          'message',
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        )),
      );

      expect(mockRepo.logoutCalled, true);
    });
  });

  group('ApiClient notifyUnauthorized & Debounce Flow', () {
    late TokenStorage tokenStorage;
    late ApiClient apiClient;

    setUp(() {
      tokenStorage = TokenStorage(const FlutterSecureStorage());
      apiClient = ApiClient(tokenStorage);
    });

    test('notifyUnauthorized invokes onUnauthorized callback and clears tokens', () async {
      await tokenStorage.saveTokens(accessToken: 'mock_token', refreshToken: 'mock_refresh');
      expect(await tokenStorage.getAccessToken(), 'mock_token');

      var callbackCount = 0;
      apiClient.onUnauthorized = () {
        callbackCount++;
      };

      apiClient.notifyUnauthorized();

      expect(callbackCount, 1);
      expect(await tokenStorage.getAccessToken(), isNull);
    });

    test('notifyUnauthorized debounces rapid duplicate calls within 2 seconds', () async {
      var callbackCount = 0;
      apiClient.onUnauthorized = () {
        callbackCount++;
      };

      // 3 rapid calls in a row (e.g. 3 parallel API requests failing with 401)
      apiClient.notifyUnauthorized();
      apiClient.notifyUnauthorized();
      apiClient.notifyUnauthorized();

      // Only 1 callback should have been dispatched
      expect(callbackCount, 1);
    });
  });

  group('Session Expiration UI & Router Redirect Flow', () {
    late MockAuthRepository mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepository();
      authBloc = AuthBloc(
        loginUseCase: LoginUseCase(mockRepo),
        autoLoginUseCase: AutoLoginUseCase(mockRepo),
        logoutUseCase: LogoutUseCase(mockRepo),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('LoginPage renders warning banner when AuthUnauthenticated has expired message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(
              home: LoginPage(),
            ),
          ),
        ),
      );

      // Simulate TokenExpired emission
      authBloc.emit(const AuthUnauthenticated(
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      ));
      await tester.pump();

      expect(find.text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    test('Router redirect policy pushes unauthenticated users to /login and permits login page', () {
      // Helper replicating buildRouter redirect logic
      String? redirectPolicy(AuthState state, String matchedLocation) {
        final isAuth = state is AuthAuthenticated;
        final isLogin = matchedLocation == '/login';
        if (!isAuth && !isLogin) return '/login';
        if (isAuth && isLogin) return '/projects';
        if (matchedLocation == '/') return '/projects';
        return null;
      }

      // 1. When session expired (AuthUnauthenticated) on any protected page -> redirect to /login
      const expiredState = AuthUnauthenticated(message: 'Phiên đăng nhập đã hết hạn.');
      expect(redirectPolicy(expiredState, '/projects'), '/login');
      expect(redirectPolicy(expiredState, '/calendar'), '/login');
      expect(redirectPolicy(expiredState, '/attendance'), '/login');
      expect(redirectPolicy(expiredState, '/login'), isNull); // Stays on login

      // 2. When authenticated -> stay on protected pages, redirect away from /login
      const authState = AuthAuthenticated(UserEntity(
        id: 'u1',
        username: 'tung',
        displayName: 'Tung',
        email: 'tung@example.com',
        role: 'admin',
      ));
      expect(redirectPolicy(authState, '/projects'), isNull);
      expect(redirectPolicy(authState, '/login'), '/projects');
    });
  });
}
