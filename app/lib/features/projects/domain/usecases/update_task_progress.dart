import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/project_repository.dart';

class UpdateTaskProgressUseCase implements UseCase<void, UpdateTaskParams> {
  final ProjectRepository repository;
  UpdateTaskProgressUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateTaskParams params) async {
    return await repository.updateTaskProgress(params.taskId, params.progress, params.status);
  }
}

class UpdateTaskParams extends Equatable {
  final String taskId;
  final double progress;
  final TaskStatus? status;

  const UpdateTaskParams({required this.taskId, required this.progress, this.status});

  @override
  List<Object?> get props => [taskId, progress, status];
}
