import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/project_repository.dart';

class GetProjectsDataUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final ProjectRepository repository;
  GetProjectsDataUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.getProjectsData();
  }
}
