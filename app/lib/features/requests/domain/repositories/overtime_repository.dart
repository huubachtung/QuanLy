import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/overtime_model.dart';

abstract class OvertimeRepository {
  Future<Either<Failure, List<OvertimeModel>>> getOvertimeData(int month, int year);
  Future<Either<Failure, void>> updateRecord(String date, double requestedHours, String reason);
  Future<Either<Failure, void>> markNoOt(String date);
  Future<Either<Failure, String>> submitBulk(List<Map<String, dynamic>> entries);
  Future<Either<Failure, void>> deleteRecord(String id);
}
