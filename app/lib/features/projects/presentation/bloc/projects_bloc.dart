import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/usecases/get_projects_data.dart';
import '../../domain/usecases/update_task_progress.dart';
import '../../domain/usecases/get_available_transitions.dart';
import '../../domain/usecases/perform_workflow_transition.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final GetProjectsDataUseCase getProjectsData;
  final UpdateTaskProgressUseCase updateTaskProgress;
  final GetAvailableTransitionsUseCase getAvailableTransitions;
  final PerformWorkflowTransitionUseCase performWorkflowTransition;

  ProjectsBloc({
    required this.getProjectsData,
    required this.updateTaskProgress,
    required this.getAvailableTransitions,
    required this.performWorkflowTransition,
  }) : super(ProjectsInitial()) {
    on<LoadProjectsData>(_onLoadProjectsData);
    on<UpdateTaskProgressEvent>(_onUpdateTaskProgress);
    on<LoadAvailableTransitions>(_onLoadAvailableTransitions);
    on<PerformWorkflowTransitionEvent>(_onPerformWorkflowTransition);
  }

  Future<void> _onLoadProjectsData(LoadProjectsData event, Emitter<ProjectsState> emit) async {
    final isRefresh = event.completer != null;
    final currentState = state;

    // Only emit full loading if not pull-refreshing existing loaded data
    if (!isRefresh && currentState is! ProjectsLoaded) {
      emit(ProjectsLoading());
    }

    try {
      final failureOrData = await getProjectsData(NoParams());
      failureOrData.fold(
        (failure) {
          if (!isRefresh || currentState is! ProjectsLoaded) {
            emit(ProjectsError(failure.message));
          }
        },
        (data) {
          final currentTransitions = currentState is ProjectsLoaded
              ? currentState.availableTransitions
              : const <String, List<AvailableTransitionModel>>{};

          emit(ProjectsLoaded(
            projects: data['projects'] as List<ProjectModel>,
            tasks: data['tasks'] as List<TaskModel>,
            schedules: data['schedules'] as List<ProjectScheduleModel>,
            availableTransitions: currentTransitions,
          ));
        },
      );
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onUpdateTaskProgress(UpdateTaskProgressEvent event, Emitter<ProjectsState> emit) async {
    final currentState = state;
    if (currentState is ProjectsLoaded) {
      // Optimistic update locally
      final updatedTasks = currentState.tasks.map((t) {
        if (t.id == event.taskId) {
          return t.copyWith(
            progress: event.progress,
            status: event.status ?? t.status,
            completedAt: event.status == TaskStatus.done ? DateTime.now() : t.completedAt,
          );
        }
        return t;
      }).toList();

      emit(currentState.copyWith(tasks: updatedTasks));

      // Actually perform remote update
      final failureOrSuccess = await updateTaskProgress(UpdateTaskParams(
        taskId: event.taskId,
        progress: event.progress,
        status: event.status,
        toStepId: event.toStepId,
      ));

      await failureOrSuccess.fold(
        (failure) async {
          emit(ProjectsError(failure.message));
          add(const LoadProjectsData()); // reload
        },
        (_) async {
          // Re-fetch from server to confirm server data changes
          final freshData = await getProjectsData(NoParams());
          freshData.fold(
            (f) => null,
            (data) => emit(ProjectsLoaded(
              projects: data['projects'] as List<ProjectModel>,
              tasks: data['tasks'] as List<TaskModel>,
              schedules: data['schedules'] as List<ProjectScheduleModel>,
              availableTransitions: currentState.availableTransitions,
            )),
          );
        },
      );
    }
  }

  Future<void> _onLoadAvailableTransitions(
      LoadAvailableTransitions event, Emitter<ProjectsState> emit) async {
    final currentState = state;
    if (currentState is! ProjectsLoaded) return;

    final result = await getAvailableTransitions(event.taskId);
    result.fold(
      (failure) {
        // Fallback: derive from task.workflowTransitions if available
        _applyFallbackTransitions(event.taskId, currentState, emit);
      },
      (transitions) {
        if (transitions.isEmpty) {
          _applyFallbackTransitions(event.taskId, currentState, emit);
        } else {
          final updatedMap = Map<String, List<AvailableTransitionModel>>.from(
              currentState.availableTransitions);
          updatedMap[event.taskId] = transitions;
          emit(currentState.copyWith(availableTransitions: updatedMap));
        }
      },
    );
  }

  void _applyFallbackTransitions(
      String taskId, ProjectsLoaded currentState, Emitter<ProjectsState> emit) {
    final taskList = currentState.tasks.where((t) => t.id == taskId);
    if (taskList.isEmpty) return;
    final task = taskList.first;

    List<AvailableTransitionModel> fallbackTransitions = [];
    if (task.workflowTransitions.isNotEmpty) {
      fallbackTransitions = task.workflowTransitions
          .where((tr) => tr.from == task.currentStepId)
          .map((tr) {
            final targetSteps = task.workflowSteps.where((s) => s.stepId == tr.to);
            final targetLabel = targetSteps.isNotEmpty ? targetSteps.first.label : tr.to;
            return AvailableTransitionModel(
              toStepId: tr.to,
              toStepLabel: targetLabel,
              type: tr.type,
              label: tr.label.isNotEmpty ? tr.label : targetLabel,
              fromStepId: tr.from,
              requiresApproval: tr.requiresApproval,
              allowedRoles: tr.allowedRoles,
            );
          })
          .toList();
    } else if (task.workflowSteps.isNotEmpty) {
      // Linear fallback if no transition matrix: move to next step by order
      final curIdx = task.workflowSteps.indexWhere((s) => s.stepId == task.currentStepId);
      if (curIdx != -1 && curIdx < task.workflowSteps.length - 1) {
        final nextStep = task.workflowSteps[curIdx + 1];
        fallbackTransitions.add(AvailableTransitionModel(
          toStepId: nextStep.stepId,
          toStepLabel: nextStep.label,
          type: nextStep.isApprovalNode ? 'APPROVE' : 'NEXT',
          label: nextStep.label,
          fromStepId: task.currentStepId,
          requiresApproval: nextStep.isApprovalNode,
        ));
      }
    }

    final updatedMap = Map<String, List<AvailableTransitionModel>>.from(
        currentState.availableTransitions);
    updatedMap[taskId] = fallbackTransitions;
    emit(currentState.copyWith(availableTransitions: updatedMap));
  }

  Future<void> _onPerformWorkflowTransition(
      PerformWorkflowTransitionEvent event, Emitter<ProjectsState> emit) async {
    final currentState = state;
    if (currentState is! ProjectsLoaded) return;

    emit(currentState.copyWith(isTransitioning: true));

    final result = await performWorkflowTransition(PerformTransitionParams(
      taskId: event.taskId,
      toStepId: event.toStepId,
    ));

    await result.fold(
      (failure) async {
        emit(currentState.copyWith(isTransitioning: false));
        emit(ProjectsError(failure.message));
        add(const LoadProjectsData());
      },
      (_) async {
        final freshData = await getProjectsData(NoParams());
        freshData.fold(
          (f) => emit(currentState.copyWith(isTransitioning: false)),
          (data) {
            emit(ProjectsLoaded(
              projects: data['projects'] as List<ProjectModel>,
              tasks: data['tasks'] as List<TaskModel>,
              schedules: data['schedules'] as List<ProjectScheduleModel>,
              isTransitioning: false,
            ));
            add(LoadAvailableTransitions(event.taskId));
          },
        );
      },
    );
  }
}
