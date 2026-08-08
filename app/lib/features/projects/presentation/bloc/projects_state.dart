import 'package:equatable/equatable.dart';
import '../../../../core/models/project_model.dart';

abstract class ProjectsState extends Equatable {
  const ProjectsState();
  
  @override
  List<Object?> get props => [];
}

class ProjectsInitial extends ProjectsState {}

class ProjectsLoading extends ProjectsState {}

class ProjectsLoaded extends ProjectsState {
  final List<ProjectModel> projects;
  final List<TaskModel> tasks;
  final List<ProjectScheduleModel> schedules;

  const ProjectsLoaded({
    required this.projects,
    required this.tasks,
    required this.schedules,
  });

  List<TaskModel> get myTasks => tasks.where((t) => t.assignedToId == 'user_001').toList();

  List<TaskModel> tasksByStatus(TaskStatus status) =>
      myTasks.where((t) => t.status == status).toList();

  List<TaskModel> tasksForProject(String projectId) =>
      tasks.where((t) => t.projectId == projectId).toList();

  ProjectsLoaded copyWith({
    List<ProjectModel>? projects,
    List<TaskModel>? tasks,
    List<ProjectScheduleModel>? schedules,
  }) {
    return ProjectsLoaded(
      projects: projects ?? this.projects,
      tasks: tasks ?? this.tasks,
      schedules: schedules ?? this.schedules,
    );
  }

  @override
  List<Object?> get props => [projects, tasks, schedules];
}

class ProjectsError extends ProjectsState {
  final String message;
  const ProjectsError(this.message);

  @override
  List<Object?> get props => [message];
}
