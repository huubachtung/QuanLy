// ── Notification Model ────────────────────────────────────────
class NotificationModel {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final String link;
  final bool isRead;
  final String? senderId;
  final String? senderName;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.link = '',
    this.isRead = false,
    this.senderId,
    this.senderName,
    this.metadata = const {},
    required this.createdAt,
  });
}

enum NotificationType {
  taskAssigned, taskTransferRequest, taskTransferApproved, taskTransferRejected,
  projectAssigned, leaveRequest, leaveApproved, leaveRejected,
  otRequest, otApproved, otRejected, workflowApproval,
  taskDeadline, mention, system, ticketNew, ticketUpdated,
}

extension NotificationTypeExt on NotificationType {
  String get tabLabel {
    switch (this) {
      case NotificationType.taskAssigned:
      case NotificationType.taskTransferRequest:
      case NotificationType.taskTransferApproved:
      case NotificationType.taskTransferRejected:
      case NotificationType.taskDeadline: return 'Task';
      case NotificationType.leaveRequest:
      case NotificationType.leaveApproved:
      case NotificationType.leaveRejected: return 'Nghỉ phép';
      case NotificationType.otRequest:
      case NotificationType.otApproved:
      case NotificationType.otRejected: return 'Tăng ca';
      default: return 'Hệ thống';
    }
  }

  String get filterKey {
    switch (this) {
      case NotificationType.taskAssigned:
      case NotificationType.taskTransferRequest:
      case NotificationType.taskTransferApproved:
      case NotificationType.taskTransferRejected:
      case NotificationType.taskDeadline: return 'task';
      case NotificationType.leaveRequest:
      case NotificationType.leaveApproved:
      case NotificationType.leaveRejected: return 'leave';
      case NotificationType.otRequest:
      case NotificationType.otApproved:
      case NotificationType.otRejected: return 'ot';
      default: return 'system';
    }
  }
}
