import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/asset_model.dart';

abstract class AssetRepository {
  Future<Either<Failure, List<AssetModel>>> getAssets();
}
