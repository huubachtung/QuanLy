import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/leave_request_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeaveRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeaveDataResponse>> getLeaveRequests() async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getLeaveRequests();
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> createRequest(LeaveRequestModel request) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.createRequest(request);
        return Right(result);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> cancelRequest(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.cancelRequest(id);
        return Right(result);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
