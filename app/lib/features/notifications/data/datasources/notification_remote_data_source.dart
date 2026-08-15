import '../../../../core/models/notification_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get(ApiConstants.notifications);
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await apiClient.dio.put('${ApiConstants.notifications}/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.dio.put('${ApiConstants.notifications}/read-all');
  }
}
