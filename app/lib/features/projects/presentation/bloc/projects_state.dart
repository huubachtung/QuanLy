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

  List<TaskModel> myTasks([String? userId]) {
    if (userId == null || userId.isEmpty) return tasks;
    return tasks.where((t) => t.assignedToId == userId).toList();
  }

  List<ProjectModel> myProjects([String? userId]) {
    if (userId == null || userId.isEmpty) return projects;
    return projects.where((p) {
      final isLeader = p.leaderId == userId;
      final isCreator = p.creatorId == userId;
      final isSupporter = p.supporterIds.contains(userId);
      final hasTask = tasks.any((t) => t.projectId == p.id && t.assignedToId == userId);
      return isLeader || isCreator || isSupporter || hasTask;
    }).toList();
  }

  List<TaskModel> tasksByStatus(TaskStatus status, [String? userId]) =>
      myTasks(userId).where((t) => t.status == status).toList();

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
