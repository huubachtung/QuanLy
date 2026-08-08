import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/attendance_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceUseCase implements UseCase<List<AttendanceModel>, GetAttendanceParams> {
  final AttendanceRepository repository;
  GetAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<AttendanceModel>>> call(GetAttendanceParams params) async {
    return await repository.getAttendanceData(params.month, params.year);
  }
}

class GetAttendanceParams extends Equatable {
  final int month;
  final int year;
  const GetAttendanceParams({required this.month, required this.year});

  @override
  List<Object?> get props => [month, year];
}
