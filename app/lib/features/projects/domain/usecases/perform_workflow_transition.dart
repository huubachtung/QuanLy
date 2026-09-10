import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/project_repository.dart';

class PerformWorkflowTransitionUseCase
    implements UseCase<void, PerformTransitionParams> {
  final ProjectRepository repository;
  PerformWorkflowTransitionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PerformTransitionParams params) async {
    return await repository.performWorkflowTransition(
      params.taskId,
      params.toStepId,
    );
  }
}

class PerformTransitionParams extends Equatable {
  final String taskId;
  final String toStepId;

  const PerformTransitionParams({
    required this.taskId,
    required this.toStepId,
  });

  @override
  List<Object?> get props => [taskId, toStepId];
}
