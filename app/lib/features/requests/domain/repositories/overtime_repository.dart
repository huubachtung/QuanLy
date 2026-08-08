import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/overtime_model.dart';

abstract class OvertimeRepository {
  Future<Either<Failure, List<OvertimeModel>>> getOvertimeData(int month, int year);
  Future<Either<Failure, void>> updateRecord(String id, double requestedHours, String reason);
  Future<Either<Failure, void>> markNoOt(String id);
}
