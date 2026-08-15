import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login(String username, String password) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(username, password);
        return Right(userModel);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return const Right(null); // Ignore logout errors
    }
  }

  @override
  Future<Either<Failure, UserEntity>> autoLogin() async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.autoLogin();
        if (userModel != null) {
          return Right(userModel);
        } else {
          return const Left(UnauthorizedFailure());
        }
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
