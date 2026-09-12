import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/attendance_correction.dart';

abstract class AttendanceCorrectionRepository {
  Future<Either<Failure, List<AttendanceCorrection>>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  });

  Future<Either<Failure, AttendanceCorrection>> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  });

  Future<Either<Failure, bool>> deleteAttendanceCorrection(String id);
}
