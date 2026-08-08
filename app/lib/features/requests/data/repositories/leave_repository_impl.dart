import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/leave_request_model.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;
  LeaveRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<LeaveRequestModel>>> getLeaveRequests() async {
    try {
      final res = await remoteDataSource.getLeaveRequests();
      return Right(res);
    } catch (e) { return const Left(ServerFailure()); }
  }

  @override
  Future<Either<Failure, bool>> createRequest(LeaveRequestModel request) async {
    try {
      final res = await remoteDataSource.createRequest(request);
      return Right(res);
    } catch (e) { return const Left(ServerFailure()); }
  }

  @override
  Future<Either<Failure, bool>> cancelRequest(String id) async {
    try {
      final res = await remoteDataSource.cancelRequest(id);
      return Right(res);
    } catch (e) { return const Left(ServerFailure()); }
  }
}
