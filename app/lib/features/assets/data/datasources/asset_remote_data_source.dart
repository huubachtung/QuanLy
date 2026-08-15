import '../../../../core/models/asset_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class AssetRemoteDataSource {
  Future<List<AssetModel>> getAssets();
}

class AssetRemoteDataSourceImpl implements AssetRemoteDataSource {
  final ApiClient apiClient;

  AssetRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AssetModel>> getAssets() async {
    final response = await apiClient.dio.get(ApiConstants.assets);
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => AssetModel.fromJson(e)).toList();
  }
}
