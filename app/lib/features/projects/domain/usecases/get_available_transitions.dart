import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/project_repository.dart';

class GetAvailableTransitionsUseCase
    implements UseCase<List<AvailableTransitionModel>, String> {
  final ProjectRepository repository;
  GetAvailableTransitionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AvailableTransitionModel>>> call(
      String taskId) async {
    return await repository.getAvailableTransitions(taskId);
  }
}
