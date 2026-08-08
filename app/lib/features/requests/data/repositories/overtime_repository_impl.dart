import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/overtime_model.dart';
import '../../domain/repositories/overtime_repository.dart';
import '../datasources/overtime_remote_data_source.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  final OvertimeRemoteDataSource remoteDataSource;
  OvertimeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<OvertimeModel>>> getOvertimeData(int month, int year) async {
    try {
      final res = await remoteDataSource.getOvertimeData(month, year);
      return Right(res);
    } catch (e) { return const Left(ServerFailure()); }
  }

  @override
  Future<Either<Failure, void>> updateRecord(String id, double requestedHours, String reason) async {
    try {
      await remoteDataSource.updateRecord(id, requestedHours, reason);
      return const Right(null);
    } catch (e) { return const Left(ServerFailure()); }
  }

  @override
  Future<Either<Failure, void>> markNoOt(String id) async {
    try {
      await remoteDataSource.markNoOt(id);
      return const Right(null);
    } catch (e) { return const Left(ServerFailure()); }
  }
}
