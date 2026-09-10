import 'package:equatable/equatable.dart';
import '../../../../core/models/project_model.dart';

abstract class ProjectsEvent extends Equatable {
  const ProjectsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectsData extends ProjectsEvent {}

class UpdateTaskProgressEvent extends ProjectsEvent {
  final String taskId;
  final double progress;
  final TaskStatus? status;
  final String? toStepId;

  const UpdateTaskProgressEvent({
    required this.taskId,
    required this.progress,
    this.status,
    this.toStepId,
  });

  @override
  List<Object?> get props => [taskId, progress, status, toStepId];
}

class LoadAvailableTransitions extends ProjectsEvent {
  final String taskId;
  const LoadAvailableTransitions(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class PerformWorkflowTransitionEvent extends ProjectsEvent {
  final String taskId;
  final String toStepId;

  const PerformWorkflowTransitionEvent({
    required this.taskId,
    required this.toStepId,
  });

  @override
  List<Object?> get props => [taskId, toStepId];
}
