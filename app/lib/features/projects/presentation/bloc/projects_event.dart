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

  const UpdateTaskProgressEvent({
    required this.taskId,
    required this.progress,
    this.status,
  });

  @override
  List<Object?> get props => [taskId, progress, status];
}
