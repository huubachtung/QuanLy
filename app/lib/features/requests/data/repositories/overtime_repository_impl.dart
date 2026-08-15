import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/overtime_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/overtime_repository.dart';
import '../datasources/overtime_remote_data_source.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  final OvertimeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  OvertimeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<OvertimeModel>>> getOvertimeData(int month, int year) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getOvertimeData(month, year);
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateRecord(String date, double requestedHours, String reason) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateRecord(date, requestedHours, reason);
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markNoOt(String date) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markNoOt(date);
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> submitBulk(List<Map<String, dynamic>> entries) async {
    if (await networkInfo.isConnected) {
      try {
        final msg = await remoteDataSource.submitBulk(entries);
        return Right(msg);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecord(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteRecord(id);
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
