import '../../../../core/models/asset_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class AssetRemoteDataSource {
  Future<List<AssetModel>> getAssets();
}

class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  @override
  Future<List<AssetModel>> getAssets() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.assets;
  }
}
