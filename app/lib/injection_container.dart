import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/network_info.dart';
import 'core/network/token_storage.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/auto_login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/projects/data/datasources/project_remote_data_source.dart';
import 'features/projects/data/repositories/project_repository_impl.dart';
import 'features/projects/domain/repositories/project_repository.dart';
import 'features/projects/domain/usecases/get_projects_data.dart';
import 'features/projects/domain/usecases/update_task_progress.dart';
import 'features/projects/domain/usecases/get_available_transitions.dart';
import 'features/projects/domain/usecases/perform_workflow_transition.dart';
import 'features/projects/presentation/bloc/projects_bloc.dart';
import 'features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/get_attendance.dart';
import 'features/attendance/presentation/bloc/attendance_bloc.dart';
import 'features/requests/data/datasources/leave_remote_data_source.dart';
import 'features/requests/data/repositories/leave_repository_impl.dart';
import 'features/requests/domain/repositories/leave_repository.dart';
import 'features/requests/domain/usecases/leave_usecases.dart';
import 'features/requests/presentation/bloc/leave/leave_bloc.dart';
import 'features/requests/data/datasources/overtime_remote_data_source.dart';
import 'features/requests/data/repositories/overtime_repository_impl.dart';
import 'features/requests/domain/repositories/overtime_repository.dart';
import 'features/requests/domain/usecases/overtime_usecases.dart';
import 'features/requests/presentation/bloc/overtime/overtime_bloc.dart';
import 'features/notifications/data/datasources/notification_remote_data_source.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/notification_usecases.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/assets/data/datasources/asset_remote_data_source.dart';
import 'features/assets/data/repositories/asset_repository_impl.dart';
import 'features/assets/domain/repositories/asset_repository.dart';
import 'features/assets/domain/usecases/get_assets.dart';
import 'features/assets/presentation/bloc/asset_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  // --- Core ---
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => TokenStorage(sl()));
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // --- Features: Auth ---
  // Bloc
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        autoLoginUseCase: sl(),
        logoutUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => AutoLoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl(), tokenStorage: sl()),
  );

  // --- Features: Home ---
  sl.registerFactory(() => HomeBloc());

  // --- Features: Projects ---
  // Bloc
  sl.registerFactory(() => ProjectsBloc(
        getProjectsData: sl(),
        updateTaskProgress: sl(),
        getAvailableTransitions: sl(),
        performWorkflowTransition: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetProjectsDataUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetAvailableTransitionsUseCase(sl()));
  sl.registerLazySingleton(() => PerformWorkflowTransitionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(apiClient: sl()),
  );

  // --- Features: Attendance ---
  // Bloc
  sl.registerFactory(() => AttendanceBloc(getAttendance: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetAttendanceUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(apiClient: sl()),
  );

  // --- Features: Requests (Leave & Overtime) ---
  // Blocs
  sl.registerFactory(
      () => LeaveBloc(getRequests: sl(), createReq: sl(), cancelReq: sl()));
  sl.registerFactory(() => OvertimeBloc(
        getOvertime: sl(),
        updateRecord: sl(),
        markNoOt: sl(),
        submitBulk: sl(),
        deleteRecord: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetLeaveRequestsUseCase(sl()));
  sl.registerLazySingleton(() => CreateLeaveRequestUseCase(sl()));
  sl.registerLazySingleton(() => CancelLeaveRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetOvertimeDataUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOvertimeRecordUseCase(sl()));
  sl.registerLazySingleton(() => MarkNoOtUseCase(sl()));
  sl.registerLazySingleton(() => SubmitBulkOvertimeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOvertimeRecordUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<LeaveRepository>(
      () => LeaveRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));
  sl.registerLazySingleton<OvertimeRepository>(
      () => OvertimeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));

  // Data sources
  sl.registerLazySingleton<LeaveRemoteDataSource>(
      () => LeaveRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<OvertimeRemoteDataSource>(
      () => OvertimeRemoteDataSourceImpl(apiClient: sl()));

  // --- Features: Notifications ---
  // Bloc
  sl.registerFactory(() => NotificationBloc(
      getNotifications: sl(), markRead: sl(), markAllRead: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));

  // Data sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(apiClient: sl()));

  // --- Features: Assets ---
  // Bloc
  sl.registerFactory(() => AssetBloc(getAssets: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetAssetsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AssetRepository>(
      () => AssetRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()));

  // Data sources
  sl.registerLazySingleton<AssetRemoteDataSource>(
      () => AssetRemoteDataSourceImpl(apiClient: sl()));
}
