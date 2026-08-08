import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/asset_model.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_remote_data_source.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDataSource remoteDataSource;
  AssetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AssetModel>>> getAssets() async {
    try {
      final data = await remoteDataSource.getAssets();
      return Right(data);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
