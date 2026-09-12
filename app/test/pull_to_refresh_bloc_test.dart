import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/models/project_model.dart';
import 'package:app/core/models/attendance_model.dart';
import 'package:app/features/projects/domain/repositories/project_repository.dart';
import 'package:app/features/projects/domain/usecases/get_projects_data.dart';
import 'package:app/features/projects/domain/usecases/update_task_progress.dart';
import 'package:app/features/projects/domain/usecases/get_available_transitions.dart';
import 'package:app/features/projects/domain/usecases/perform_workflow_transition.dart';
import 'package:app/features/projects/presentation/bloc/projects_bloc.dart';
import 'package:app/features/projects/presentation/bloc/projects_event.dart';
import 'package:app/features/projects/presentation/bloc/projects_state.dart';
import 'package:app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:app/features/attendance/domain/usecases/get_attendance.dart';
import 'package:app/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:app/features/attendance/presentation/bloc/attendance_state.dart';

class MockProjectsRepo implements ProjectRepository {
  bool shouldFail = false;
  int fetchCallCount = 0;

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProjectsData() async {
    fetchCallCount++;
    if (shouldFail) {
      return const Left(ServerFailure('Mock network error'));
    }
    return Right({
      'projects': <ProjectModel>[
        ProjectModel(
          id: 'p1',
          name: 'Project Alpha',
          description: 'Desc',
          creatorId: 'u1',
          leaderId: 'u1',
          leaderName: 'Leader',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          status: ProjectStatus.inProgress,
        ),
      ],
      'tasks': <TaskModel>[],
      'schedules': <ProjectScheduleModel>[],
    });
  }

  @override
  Future<Either<Failure, void>> updateTaskProgress(
    String taskId,
    double progress,
    TaskStatus? status, {
    String? toStepId,
  }) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<AvailableTransitionModel>>> getAvailableTransitions(
    String taskId,
  ) async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> performWorkflowTransition(
    String taskId,
    String toStepId,
  ) async =>
      const Right(null);
}

class MockAttendanceRepo implements AttendanceRepository {
  bool shouldFail = false;
  int fetchCallCount = 0;

  @override
  Future<Either<Failure, AttendanceResponseModel>> getAttendanceData(
    int month,
    int year,
  ) async {
    fetchCallCount++;
    if (shouldFail) {
      return const Left(ServerFailure('Mock attendance server error'));
    }
    return Right(AttendanceResponseModel(
      summary: AttendanceSummary(
        workDays: 10 + fetchCallCount,
        totalNormalHours: 80,
        approvedOtHours: 2,
        pendingOtHours: 0,
        totalCong: 10,
      ),
      records: [
        const AttendanceModel(
          id: 'att_1',
          userId: 'u1',
          date: '2026-09-01',
          dailyCong: 1.0,
          normalHours: 8.0,
          status: AttendanceStatus.done,
        ),
      ],
    ));
  }
}

void main() {
  group('ProjectsBloc Pull-to-Refresh Tests', () {
    late MockProjectsRepo mockRepo;
    late ProjectsBloc bloc;

    setUp(() {
      mockRepo = MockProjectsRepo();
      bloc = ProjectsBloc(
        getProjectsData: GetProjectsDataUseCase(mockRepo),
        updateTaskProgress: UpdateTaskProgressUseCase(mockRepo),
        getAvailableTransitions: GetAvailableTransitionsUseCase(mockRepo),
        performWorkflowTransition: PerformWorkflowTransitionUseCase(mockRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial load emits ProjectsLoading then ProjectsLoaded', () async {
      bloc.add(const LoadProjectsData());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoading>(),
          isA<ProjectsLoaded>(),
        ]),
      );
      expect(mockRepo.fetchCallCount, 1);
    });

    test('Pull-to-refresh Completer completes successfully and avoids flashing ProjectsLoading when already loaded',
        () async {
      // 1. Initial load
      bloc.add(const LoadProjectsData());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoading>(),
          isA<ProjectsLoaded>(),
        ]),
      );

      // 2. Trigger pull-to-refresh with Completer
      final completer = Completer<void>();
      bloc.add(LoadProjectsData(completer: completer));

      // Stream should emit fresh ProjectsLoaded WITHOUT emitting ProjectsLoading in-between
      await expectLater(
        bloc.stream,
        emits(isA<ProjectsLoaded>()),
      );

      // Verify completer completed smoothly
      await expectLater(completer.future, completes);
      expect(mockRepo.fetchCallCount, 2);
    });

    test('Completer completes even when fetch fails (defensive UI: no hanging spinner)',
        () async {
      mockRepo.shouldFail = true;

      final completer = Completer<void>();
      bloc.add(LoadProjectsData(completer: completer));

      await expectLater(
        bloc.stream,
        emits(isA<ProjectsError>()),
      );

      // Completer must complete despite failure
      await expectLater(completer.future, completes);
    });
  });

  group('AttendanceBloc Pull-to-Refresh Tests', () {
    late MockAttendanceRepo mockRepo;
    late AttendanceBloc bloc;

    setUp(() {
      mockRepo = MockAttendanceRepo();
      bloc = AttendanceBloc(
        getAttendance: GetAttendanceUseCase(mockRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial load emits AttendanceLoading then AttendanceLoaded', () async {
      bloc.add(const LoadAttendanceData(month: 9, year: 2026));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoading>(),
          isA<AttendanceLoaded>(),
        ]),
      );
      expect(mockRepo.fetchCallCount, 1);
    });

    test('Pull-to-refresh Completer completes successfully and avoids flashing AttendanceLoading when already loaded',
        () async {
      // 1. Initial load
      bloc.add(const LoadAttendanceData(month: 9, year: 2026));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceLoading>(),
          isA<AttendanceLoaded>(),
        ]),
      );

      // 2. Trigger pull-to-refresh with Completer
      final completer = Completer<void>();
      bloc.add(LoadAttendanceData(month: 9, year: 2026, completer: completer));

      // Emits fresh AttendanceLoaded directly
      await expectLater(
        bloc.stream,
        emits(isA<AttendanceLoaded>()),
      );

      // Verify completer completed
      await expectLater(completer.future, completes);
      expect(mockRepo.fetchCallCount, 2);
    });

    test('Attendance Completer completes even when fetch fails (no hanging spinner)',
        () async {
      mockRepo.shouldFail = true;

      final completer = Completer<void>();
      bloc.add(LoadAttendanceData(month: 9, year: 2026, completer: completer));

      await expectLater(
        bloc.stream,
        emits(isA<AttendanceError>()),
      );

      // Completer must complete despite failure
      await expectLater(completer.future, completes);
    });
  });
}
