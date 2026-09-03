import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, NotificationListResult>> getNotifications() async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getNotifications();
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAsRead(id);
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllAsRead();
        return const Right(null);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
