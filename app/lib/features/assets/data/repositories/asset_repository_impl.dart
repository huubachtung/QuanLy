import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/asset_model.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_remote_data_source.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AssetRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AssetModel>>> getAssets() async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getAssets();
        return Right(data);
      } on Exception catch (e) {
        return Left(Failure.fromException(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
