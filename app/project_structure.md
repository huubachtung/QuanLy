# Project Structure

This project follows Clean Architecture principles with a feature-driven folder structure, commonly used in Flutter apps utilizing BLoC for state management.

```text
app/
├── assets/
│   ├── fonts/
│   └── images/
│       ├── Logo.png
│       ├── project.png
│       ├── sys_update.png
│       ├── task.png
│       ├── timer.png
│       └── vacation.png
├── lib/
│   ├── injection_container.dart
│   ├── main.dart
│   ├── app/
│   │   └── router.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── mock/
│   │   │   └── mock_data.dart
│   │   ├── models/
│   │   │   ├── asset_model.dart
│   │   │   ├── attendance_model.dart
│   │   │   ├── leave_request_model.dart
│   │   │   ├── notification_model.dart
│   │   │   ├── overtime_model.dart
│   │   │   ├── project_model.dart
│   │   │   └── user_model.dart
│   │   ├── network/
│   │   │   └── network_info.dart
│   │   ├── providers/
│   │   │   └── theme_provider.dart
│   │   ├── usecases/
│   │   │   └── usecase.dart
│   │   └── utils/
│   │       ├── app_colors.dart
│   │       └── theme.dart
│   ├── features/
│   │   ├── assets/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── asset_remote_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── asset_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/
│   │   │   │   │   └── asset_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── get_assets.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── asset_bloc.dart
│   │   │       │   ├── asset_event.dart
│   │   │       │   └── asset_state.dart
│   │   │       └── pages/
│   │   │           ├── asset_detail_page.dart
│   │   │           └── asset_page.dart
│   │   ├── attendance/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── attendance_remote_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── attendance_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/
│   │   │   │   │   └── attendance_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── get_attendance.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── attendance_bloc.dart
│   │   │       │   ├── attendance_event.dart
│   │   │       │   └── attendance_state.dart
│   │   │       └── pages/
│   │   │           └── attendance_page.dart
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── auth_remote_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── login_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       └── pages/
│   │   │           └── login_page.dart
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── home_bloc.dart
│   │   │       │   ├── home_event.dart
│   │   │       │   └── home_state.dart
│   │   │       └── pages/
│   │   │           └── home_page.dart
│   │   ├── notifications/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── notification_remote_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── notification_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/
│   │   │   │   │   └── notification_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── notification_usecases.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── notification_bloc.dart
│   │   │       │   ├── notification_event.dart
│   │   │       │   └── notification_state.dart
│   │   │       └── pages/
│   │   │           └── notification_page.dart
│   │   ├── profile/
│   │   │   └── presentation/
│   │   │       └── pages/
│   │   │           └── profile_page.dart
│   │   ├── projects/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── project_remote_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── project_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/
│   │   │   │   │   └── project_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_projects_data.dart
│   │   │   │       └── update_task_progress.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── projects_bloc.dart
│   │   │       │   ├── projects_event.dart
│   │   │       │   └── projects_state.dart
│   │   │       └── pages/
│   │   │           ├── project_calendar_page.dart
│   │   │           ├── project_detail_page.dart
│   │   │           ├── project_list_page.dart
│   │   │           ├── task_detail_page.dart
│   │   │           ├── task_list_page.dart
│   │   │           └── timeline_page.dart
│   │   └── requests/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── leave_remote_data_source.dart
│   │       │   │   └── overtime_remote_data_source.dart
│   │       │   └── repositories/
│   │       │       ├── leave_repository_impl.dart
│   │       │       └── overtime_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── repositories/
│   │       │   │   ├── leave_repository.dart
│   │       │   │   └── overtime_repository.dart
│   │       │   └── usecases/
│   │       │       ├── leave_usecases.dart
│   │       │       └── overtime_usecases.dart
│   │       └── presentation/
│   │           ├── bloc/
│   │           │   ├── leave/
│   │           │   │   ├── leave_bloc.dart
│   │           │   │   ├── leave_event.dart
│   │           │   │   └── leave_state.dart
│   │           │   └── overtime/
│   │           │       ├── overtime_bloc.dart
│   │           │       ├── overtime_event.dart
│   │           │       └── overtime_state.dart
│   │           └── pages/
│   │               ├── leave_request_page.dart
│   │               ├── overtime_page.dart
│   │               └── request_list_page.dart
│   └── shared/
│       └── widgets/
│           ├── empty_state.dart
│           ├── loading_shimmer.dart
│           ├── month_picker.dart
│           └── status_badge.dart
└── test/
    └── widget_test.dart
```
