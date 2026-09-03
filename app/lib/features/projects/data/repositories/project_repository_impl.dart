import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProjectRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProjectsData() async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getProjectsData();
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTaskProgress(
      String taskId, double progress, TaskStatus? status, {String? toStepId}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateTaskProgress(taskId, progress, status, toStepId: toStepId);
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
