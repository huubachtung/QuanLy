import '../../../../core/models/notification_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  List<NotificationModel> _cache = List.from(MockData.notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cache;
  }

  @override
  Future<void> markAsRead(String id) async {
    final idx = _cache.indexWhere((n) => n.id == id);
    if (idx != -1 && !_cache[idx].isRead) {
      final old = _cache[idx];
      _cache[idx] = NotificationModel(
        id: old.id, recipientId: old.recipientId, type: old.type,
        title: old.title, body: old.body, link: old.link,
        isRead: true, senderId: old.senderId, senderName: old.senderName,
        metadata: old.metadata, createdAt: old.createdAt,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    _cache = _cache.map((n) => NotificationModel(
      id: n.id, recipientId: n.recipientId, type: n.type,
      title: n.title, body: n.body, link: n.link, isRead: true,
      senderId: n.senderId, senderName: n.senderName,
      metadata: n.metadata, createdAt: n.createdAt,
    )).toList();
  }
}
