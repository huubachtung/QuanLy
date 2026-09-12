import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:app/core/errors/failures.dart';
import 'package:app/core/models/project_model.dart';
import 'package:app/features/projects/domain/repositories/project_repository.dart';
import 'package:app/features/projects/domain/usecases/get_projects_data.dart';
import 'package:app/features/projects/domain/usecases/update_task_progress.dart';
import 'package:app/features/projects/domain/usecases/get_available_transitions.dart';
import 'package:app/features/projects/domain/usecases/perform_workflow_transition.dart';
import 'package:app/features/projects/presentation/bloc/projects_bloc.dart';
import 'package:app/features/projects/presentation/bloc/projects_event.dart';
import 'package:app/features/projects/presentation/bloc/projects_state.dart';
import 'package:app/features/projects/presentation/pages/task_detail_page.dart';

class MockProjectRepository implements ProjectRepository {
  List<AvailableTransitionModel> mockTransitions = [];
  bool transitionCalled = false;
  String lastTransitionStepId = '';

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProjectsData() async {
    return Right({
      'projects': <ProjectModel>[
        ProjectModel(
          id: 'p1',
          name: 'Project Test',
          description: 'Desc',
          creatorId: 'u2',
          leaderId: 'u2',
          leaderName: 'Tran Leader',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          status: ProjectStatus.inProgress,
        ),
      ],
      'tasks': <TaskModel>[
        const TaskModel(
          id: 'task_001',
          name: 'Feature X Coding',
          projectId: 'p1',
          projectName: 'Project Test',
          assignedToId: 'u1',
          assignedToName: 'Nguyen Van Dev',
          reporterId: 'u2',
          reporterName: 'Tran Leader',
          status: TaskStatus.inProgress,
          currentStepId: 'CODING',
          workflowSteps: [
            WorkflowStepModel(
              id: 's1',
              stepId: 'CODING',
              label: 'Đang Code',
              order: 1,
            ),
            WorkflowStepModel(
              id: 's2',
              stepId: 'LOCAL_TEST',
              label: 'Tự Test',
              order: 2,
            ),
            WorkflowStepModel(
              id: 's3',
              stepId: 'CODE_REVIEW',
              label: 'Review Code',
              order: 3,
              isApprovalNode: true,
            ),
            WorkflowStepModel(
              id: 's4',
              stepId: 'DONE',
              label: 'Hoàn thành',
              order: 4,
            ),
          ],
          workflowTransitions: [
            WorkflowTransitionModel(
              from: 'CODING',
              to: 'LOCAL_TEST',
              type: 'NEXT',
              label: 'Xong Code -> Test',
            ),
            WorkflowTransitionModel(
              from: 'LOCAL_TEST',
              to: 'CODE_REVIEW',
              type: 'NEXT',
              label: 'Gửi Review',
            ),
            WorkflowTransitionModel(
              from: 'CODE_REVIEW',
              to: 'DONE',
              type: 'APPROVE',
              label: 'Duyệt Merged',
            ),
          ],
        ),
      ],
      'schedules': <ProjectScheduleModel>[],
    });
  }

  @override
  Future<Either<Failure, void>> updateTaskProgress(
      String taskId, double progress, TaskStatus? status,
      {String? toStepId}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<AvailableTransitionModel>>> getAvailableTransitions(
      String taskId) async {
    return Right(mockTransitions);
  }

  @override
  Future<Either<Failure, void>> performWorkflowTransition(
      String taskId, String toStepId) async {
    transitionCalled = true;
    lastTransitionStepId = toStepId;
    return const Right(null);
  }
}

void main() {
  group('Workflow Models Parsing Tests', () {
    test('WorkflowTransitionModel parses JSON correctly', () {
      final json = {
        '_id': 'trans_123',
        'from': 'CODING',
        'to': 'LOCAL_TEST',
        'type': 'NEXT',
        'label': 'Chuyển sang test',
        'allowedRoles': ['dev', 'leader'],
        'requiresApproval': false,
        'conditionNote': 'Phải qua lint',
      };

      final model = WorkflowTransitionModel.fromJson(json);

      expect(model.id, 'trans_123');
      expect(model.from, 'CODING');
      expect(model.to, 'LOCAL_TEST');
      expect(model.type, 'NEXT');
      expect(model.label, 'Chuyển sang test');
      expect(model.allowedRoles, ['dev', 'leader']);
      expect(model.requiresApproval, false);
      expect(model.conditionNote, 'Phải qua lint');
    });

    test('AvailableTransitionModel parses JSON correctly', () {
      final json = {
        'toStepId': 'CODE_REVIEW',
        'toStepLabel': 'Review Code',
        'type': 'APPROVE',
        'label': 'Gửi Review',
        'fromStepId': 'LOCAL_TEST',
        'requiresApproval': true,
      };

      final model = AvailableTransitionModel.fromJson(json);

      expect(model.toStepId, 'CODE_REVIEW');
      expect(model.toStepLabel, 'Review Code');
      expect(model.type, 'APPROVE');
      expect(model.label, 'Gửi Review');
      expect(model.fromStepId, 'LOCAL_TEST');
      expect(model.requiresApproval, true);
    });

    test('TaskModel parses workflow_template steps and transitions', () {
      final json = {
        '_id': 'task_123',
        'name': 'API Integration',
        'project': {'_id': 'proj_1', 'name': 'Alpha'},
        'assigned_to': {'_id': 'u1', 'displayName': 'Alice'},
        'reporter': {'_id': 'u2', 'displayName': 'Bob'},
        'progress': 40,
        'status': {'_id': 'stat_1', 'name': 'CODING'},
        'workflow_template': {
          'steps': [
            {
              'stepId': 'CODING',
              'label': 'Đang Code',
              'order': 1,
              'isApprovalNode': false,
            },
            {
              'stepId': 'DONE',
              'label': 'Hoàn thành',
              'order': 2,
              'isApprovalNode': true,
            },
          ],
          'transitions': [
            {
              'from': 'CODING',
              'to': 'DONE',
              'type': 'NEXT',
              'label': 'Hoàn tất',
            },
          ],
        },
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, 'task_123');
      expect(task.name, 'API Integration');
      expect(task.workflowSteps.length, 2);
      expect(task.workflowSteps[0].stepId, 'CODING');
      expect(task.workflowSteps[1].stepId, 'DONE');
      expect(task.workflowTransitions.length, 1);
      expect(task.workflowTransitions[0].from, 'CODING');
      expect(task.workflowTransitions[0].to, 'DONE');
      expect(task.currentStepId, 'CODING');
    });
  });

  group('ProjectsBloc Workflow Transition Logic Tests', () {
    late MockProjectRepository mockRepo;
    late ProjectsBloc bloc;

    setUp(() {
      mockRepo = MockProjectRepository();
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

    test('LoadAvailableTransitions fetches API transitions and updates state',
        () async {
      mockRepo.mockTransitions = [
        const AvailableTransitionModel(
          toStepId: 'LOCAL_TEST',
          toStepLabel: 'Tự Test',
          type: 'NEXT',
          label: 'Chuyển sang Tự Test',
        ),
      ];

      // Initial load
      bloc.add(const LoadProjectsData());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoading>(),
          isA<ProjectsLoaded>(),
        ]),
      );

      // Load transitions
      bloc.add(const LoadAvailableTransitions('task_001'));
      await expectLater(
        bloc.stream,
        emits(isA<ProjectsLoaded>().having(
          (s) => s.transitionsForTask('task_001').length,
          'transitions length',
          1,
        )),
      );

      final state = bloc.state as ProjectsLoaded;
      expect(state.transitionsForTask('task_001').first.toStepId, 'LOCAL_TEST');
      expect(
          state.transitionsForTask('task_001').first.label, 'Chuyển sang Tự Test');
    });

    test(
        'LoadAvailableTransitions falls back to task.workflowTransitions when API returns empty',
        () async {
      mockRepo.mockTransitions = []; // API returns empty

      bloc.add(const LoadProjectsData());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoading>(),
          isA<ProjectsLoaded>(),
        ]),
      );

      bloc.add(const LoadAvailableTransitions('task_001'));
      await expectLater(
        bloc.stream,
        emits(isA<ProjectsLoaded>().having(
          (s) => s.transitionsForTask('task_001').isNotEmpty,
          'has fallback transitions',
          true,
        )),
      );

      final state = bloc.state as ProjectsLoaded;
      final transitions = state.transitionsForTask('task_001');
      expect(transitions.first.toStepId, 'LOCAL_TEST');
    });

    test('PerformWorkflowTransitionEvent executes transition and reloads',
        () async {
      bloc.add(const LoadProjectsData());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoading>(),
          isA<ProjectsLoaded>(),
        ]),
      );

      bloc.add(const PerformWorkflowTransitionEvent(
        taskId: 'task_001',
        toStepId: 'LOCAL_TEST',
      ));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectsLoaded>().having(
              (s) => s.isTransitioning, 'isTransitioning true', true),
          isA<ProjectsLoaded>().having(
              (s) => s.isTransitioning, 'isTransitioning false', false),
          isA<ProjectsLoaded>(), // from LoadAvailableTransitions
        ]),
      );

      expect(mockRepo.transitionCalled, true);
      expect(mockRepo.lastTransitionStepId, 'LOCAL_TEST');
    });
  });

  group('TaskDetailPage UI Pipeline Stepper Tests', () {
    testWidgets(
        'Renders Stepper steps and Action Button based on available transitions',
        (WidgetTester tester) async {
      final mockRepo = MockProjectRepository();
      mockRepo.mockTransitions = [
        const AvailableTransitionModel(
          toStepId: 'LOCAL_TEST',
          toStepLabel: 'Tự Test',
          type: 'NEXT',
          label: 'Gửi Test',
        ),
      ];

      final bloc = ProjectsBloc(
        getProjectsData: GetProjectsDataUseCase(mockRepo),
        updateTaskProgress: UpdateTaskProgressUseCase(mockRepo),
        getAvailableTransitions: GetAvailableTransitionsUseCase(mockRepo),
        performWorkflowTransition: PerformWorkflowTransitionUseCase(mockRepo),
      );

      bloc.add(const LoadProjectsData());
      await tester.pumpWidget(
        BlocProvider<ProjectsBloc>.value(
          value: bloc,
          child: const MaterialApp(
            home: TaskDetailPage(taskId: 'task_001'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Feature X Coding'), findsOneWidget);
      expect(find.text('Tiến trình giai đoạn'), findsOneWidget);

      // Verify Stepper labels
      expect(find.text('Đang Code'), findsOneWidget);
      expect(find.text('Tự Test'), findsOneWidget);
      expect(find.text('Review Code'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsOneWidget);

      // Verify current step badge (appears in info row and stepper active badge)
      expect(find.text('Đang làm'), findsNWidgets(2));

      // Verify Action Button rendered
      expect(find.text('Chuyển sang: Gửi Test'), findsOneWidget);

      // Tap action button to verify confirm dialog
      await tester.tap(find.text('Chuyển sang: Gửi Test'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận chuyển bước'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(mockRepo.transitionCalled, true);
      expect(mockRepo.lastTransitionStepId, 'LOCAL_TEST');

      bloc.close();
    });
  });
}