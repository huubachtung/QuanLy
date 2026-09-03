import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/project_model.dart';

abstract class ProjectRepository {
  Future<Either<Failure, Map<String, dynamic>>> getProjectsData();
  Future<Either<Failure, void>> updateTaskProgress(
      String taskId, double progress, TaskStatus? status, {String? toStepId});
}
