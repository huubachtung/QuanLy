import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;

  ProjectRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProjectsData() async {
    try {
      final data = await remoteDataSource.getProjectsData();
      return Right(data);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTaskProgress(String taskId, double progress, TaskStatus? status) async {
    try {
      await remoteDataSource.updateTaskProgress(taskId, progress, status);
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
