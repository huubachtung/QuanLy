import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/asset_model.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/asset_repository.dart';

class GetAssetsUseCase implements UseCase<List<AssetModel>, NoParams> {
  final AssetRepository repository;
  GetAssetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AssetModel>>> call(NoParams params) async {
    return await repository.getAssets();
  }
}
