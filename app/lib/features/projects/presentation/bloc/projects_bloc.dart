import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/usecases/get_projects_data.dart';
import '../../domain/usecases/update_task_progress.dart';
import 'projects_event.dart';
import 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final GetProjectsDataUseCase getProjectsData;
  final UpdateTaskProgressUseCase updateTaskProgress;

  ProjectsBloc({
    required this.getProjectsData,
    required this.updateTaskProgress,
  }) : super(ProjectsInitial()) {
    on<LoadProjectsData>(_onLoadProjectsData);
    on<UpdateTaskProgressEvent>(_onUpdateTaskProgress);
  }

  Future<void> _onLoadProjectsData(LoadProjectsData event, Emitter<ProjectsState> emit) async {
    emit(ProjectsLoading());
    final failureOrData = await getProjectsData(NoParams());
    failureOrData.fold(
      (failure) => emit(ProjectsError(failure.message)),
      (data) => emit(ProjectsLoaded(
        projects: data['projects'] as List<ProjectModel>,
        tasks: data['tasks'] as List<TaskModel>,
        schedules: data['schedules'] as List<ProjectScheduleModel>,
      )),
    );
  }

  Future<void> _onUpdateTaskProgress(UpdateTaskProgressEvent event, Emitter<ProjectsState> emit) async {
    final currentState = state;
    if (currentState is ProjectsLoaded) {
      // Optimistic update locally
      final updatedTasks = currentState.tasks.map((t) {
        if (t.id == event.taskId) {
          return TaskModel(
            id: t.id, name: t.name, description: t.description,
            projectId: t.projectId, projectName: t.projectName,
            assignedToId: t.assignedToId, assignedToName: t.assignedToName,
            reporterId: t.reporterId, reporterName: t.reporterName,
            progress: event.progress,
            status: event.status ?? t.status,
            startDate: t.startDate, deadlineDate: t.deadlineDate,
            completedAt: event.status == TaskStatus.done ? DateTime.now() : t.completedAt,
            difficulty: t.difficulty, priority: t.priority, requiredSkill: t.requiredSkill,
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
      ));

      failureOrSuccess.fold(
        (failure) {
          // Revert if failed - basic approach: reload or emit error (skipping complex revert for now)
          emit(ProjectsError(failure.message));
          add(LoadProjectsData()); // reload
        },
        (_) => null,
      );
    }
  }
}
