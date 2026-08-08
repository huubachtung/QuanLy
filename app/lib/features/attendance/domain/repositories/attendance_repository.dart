import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, List<AttendanceModel>>> getAttendanceData(int month, int year);
}
