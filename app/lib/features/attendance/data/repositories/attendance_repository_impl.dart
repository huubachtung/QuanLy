import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AttendanceResponseModel>> getAttendanceData(int month, int year) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getAttendanceData(month, year);
        return Right(data);
      } catch (e) {
        return Left(Failure.fromException(e is Exception ? e : Exception(e.toString())));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
