import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/attendance_correction.dart';
import '../repositories/attendance_correction_repository.dart';

class GetAttendanceCorrectionParams {
  final int? month;
  final int? year;
  final String? status;
  final String? userId;

  const GetAttendanceCorrectionParams({
    this.month,
    this.year,
    this.status,
    this.userId,
  });
}

class GetAttendanceCorrectionsUseCase
    implements UseCase<List<AttendanceCorrection>, GetAttendanceCorrectionParams> {
  final AttendanceCorrectionRepository repository;

  GetAttendanceCorrectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceCorrection>>> call(
      GetAttendanceCorrectionParams params) {
    return repository.getAttendanceCorrections(
      month: params.month,
      year: params.year,
      status: params.status,
      userId: params.userId,
    );
  }
}

class CreateAttendanceCorrectionParams {
  final String userId;
  final String date;
  final String? timeIn;
  final String? timeOut;
  final String reason;

  const CreateAttendanceCorrectionParams({
    required this.userId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.reason,
  });
}

class CreateAttendanceCorrectionUseCase
    implements UseCase<AttendanceCorrection, CreateAttendanceCorrectionParams> {
  final AttendanceCorrectionRepository repository;

  CreateAttendanceCorrectionUseCase(this.repository);

  @override
  Future<Either<Failure, AttendanceCorrection>> call(
      CreateAttendanceCorrectionParams params) {
    return repository.createAttendanceCorrection(
      userId: params.userId,
      date: params.date,
      timeIn: params.timeIn,
      timeOut: params.timeOut,
      reason: params.reason,
    );
  }
}

class DeleteAttendanceCorrectionUseCase implements UseCase<bool, String> {
  final AttendanceCorrectionRepository repository;

  DeleteAttendanceCorrectionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String id) {
    return repository.deleteAttendanceCorrection(id);
  }
}
