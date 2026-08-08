import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/leave_request_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/leave_repository.dart';

class GetLeaveRequestsUseCase implements UseCase<List<LeaveRequestModel>, NoParams> {
  final LeaveRepository repository;
  GetLeaveRequestsUseCase(this.repository);
  @override Future<Either<Failure, List<LeaveRequestModel>>> call(NoParams params) => repository.getLeaveRequests();
}

class CreateLeaveRequestUseCase implements UseCase<bool, LeaveRequestModel> {
  final LeaveRepository repository;
  CreateLeaveRequestUseCase(this.repository);
  @override Future<Either<Failure, bool>> call(LeaveRequestModel params) => repository.createRequest(params);
}

class CancelLeaveRequestUseCase implements UseCase<bool, String> {
  final LeaveRepository repository;
  CancelLeaveRequestUseCase(this.repository);
  @override Future<Either<Failure, bool>> call(String params) => repository.cancelRequest(params);
}
