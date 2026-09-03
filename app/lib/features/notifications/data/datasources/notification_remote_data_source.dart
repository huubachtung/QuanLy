import '../../../../core/models/notification_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationListResult> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<NotificationListResult> getNotifications() async {
    final response = await apiClient.dio.get(ApiConstants.notifications);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return NotificationListResult.fromJson(data);
    }
    return const NotificationListResult(notifications: [], unreadCount: 0);
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
