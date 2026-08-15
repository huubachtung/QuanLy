import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/overtime_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/overtime_repository.dart';

class GetOvertimeDataUseCase implements UseCase<List<OvertimeModel>, GetOvertimeParams> {
  final OvertimeRepository repository;
  GetOvertimeDataUseCase(this.repository);
  @override
  Future<Either<Failure, List<OvertimeModel>>> call(GetOvertimeParams params) =>
      repository.getOvertimeData(params.month, params.year);
}

class UpdateOvertimeRecordUseCase implements UseCase<void, UpdateOvertimeParams> {
  final OvertimeRepository repository;
  UpdateOvertimeRecordUseCase(this.repository);
  @override
  Future<Either<Failure, void>> call(UpdateOvertimeParams params) =>
      repository.updateRecord(params.date, params.requestedHours, params.reason);
}

class MarkNoOtUseCase implements UseCase<void, String> {
  final OvertimeRepository repository;
  MarkNoOtUseCase(this.repository);
  @override
  Future<Either<Failure, void>> call(String params) => repository.markNoOt(params);
}

class SubmitBulkOvertimeUseCase implements UseCase<String, List<Map<String, dynamic>>> {
  final OvertimeRepository repository;
  SubmitBulkOvertimeUseCase(this.repository);
  @override
  Future<Either<Failure, String>> call(List<Map<String, dynamic>> params) =>
      repository.submitBulk(params);
}

class DeleteOvertimeRecordUseCase implements UseCase<void, String> {
  final OvertimeRepository repository;
  DeleteOvertimeRecordUseCase(this.repository);
  @override
  Future<Either<Failure, void>> call(String params) => repository.deleteRecord(params);
}

class GetOvertimeParams extends Equatable {
  final int month, year;
  const GetOvertimeParams({required this.month, required this.year});
  @override
  List<Object?> get props => [month, year];
}

class UpdateOvertimeParams extends Equatable {
  final String date;
  final double requestedHours;
  final String reason;
  const UpdateOvertimeParams({
    required this.date,
    required this.requestedHours,
    required this.reason,
  });
  @override
  List<Object?> get props => [date, requestedHours, reason];
}
