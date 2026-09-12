import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/attendance_correction.dart';
import '../../domain/repositories/attendance_correction_repository.dart';
import '../datasources/attendance_correction_remote_data_source.dart';

class AttendanceCorrectionRepositoryImpl
    implements AttendanceCorrectionRepository {
  final AttendanceCorrectionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceCorrectionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AttendanceCorrection>>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getAttendanceCorrections(
          month: month,
          year: year,
          status: status,
          userId: userId,
        );
        return Right(models);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, AttendanceCorrection>> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.createAttendanceCorrection(
          userId: userId,
          date: date,
          timeIn: timeIn,
          timeOut: timeOut,
          reason: reason,
        );
        return Right(model);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAttendanceCorrection(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.deleteAttendanceCorrection(id);
        return Right(success);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
