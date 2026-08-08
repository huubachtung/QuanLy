import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/attendance_model.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AttendanceModel>>> getAttendanceData(int month, int year) async {
    try {
      final data = await remoteDataSource.getAttendanceData(month, year);
      return Right(data);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
