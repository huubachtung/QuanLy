import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/auto_login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final AutoLoginUseCase autoLoginUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.autoLoginUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AutoLoginRequested>(_onAutoLoginRequested);
    on<TokenExpired>(_onTokenExpired);
    on<UserProfileRefreshRequested>(_onUserProfileRefreshRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final failureOrUser = await loginUseCase(
      LoginParams(username: event.username, password: event.password),
    );

    failureOrUser.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAutoLoginRequested(AutoLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final failureOrUser = await autoLoginUseCase(NoParams());

    failureOrUser.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await logoutUseCase(NoParams());
    emit(const AuthUnauthenticated());
  }

  Future<void> _onTokenExpired(TokenExpired event, Emitter<AuthState> emit) async {
    await logoutUseCase(NoParams());
    emit(const AuthUnauthenticated(
      message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ));
  }

  Future<void> _onUserProfileRefreshRequested(UserProfileRefreshRequested event, Emitter<AuthState> emit) async {
    final failureOrUser = await autoLoginUseCase(NoParams());
    failureOrUser.fold(
      (_) {},
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
