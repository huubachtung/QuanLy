import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/leave_request_model.dart';

abstract class LeaveRepository {
  Future<Either<Failure, LeaveDataResponse>> getLeaveRequests();
  Future<Either<Failure, bool>> createRequest(LeaveRequestModel request);
  Future<Either<Failure, bool>> cancelRequest(String id);
}
