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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recipientId: (json['recipient'] is Map ? json['recipient']['_id'] : json['recipient'])?.toString() ?? json['recipientId']?.toString() ?? '',
      type: _parseNotificationType(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      isRead: json['isRead'] ?? false,
      senderId: json['senderId']?.toString() ?? (json['sender'] is Map ? json['sender']['_id'] : json['sender'])?.toString(),
      senderName: json['senderName']?.toString() ?? (json['sender'] is Map ? json['sender']['displayName'] : null)?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now() : DateTime.now(),
    );
  }
}

NotificationType _parseNotificationType(String? type) {
  switch (type?.toUpperCase()) {
    case 'TASK_ASSIGNED': return NotificationType.taskAssigned;
    case 'TASK_TRANSFER_REQUEST': return NotificationType.taskTransferRequest;
    case 'TASK_TRANSFER_APPROVED': return NotificationType.taskTransferApproved;
    case 'TASK_TRANSFER_REJECTED': return NotificationType.taskTransferRejected;
    case 'PROJECT_ASSIGNED': return NotificationType.projectAssigned;
    case 'LEAVE_REQUEST': return NotificationType.leaveRequest;
    case 'LEAVE_APPROVED': return NotificationType.leaveApproved;
    case 'LEAVE_REJECTED': return NotificationType.leaveRejected;
    case 'OT_REQUEST': return NotificationType.otRequest;
    case 'OT_APPROVED': return NotificationType.otApproved;
    case 'OT_REJECTED': return NotificationType.otRejected;
    case 'WORKFLOW_APPROVAL': return NotificationType.workflowApproval;
    case 'TASK_DEADLINE': return NotificationType.taskDeadline;
    case 'MENTION': return NotificationType.mention;
    case 'TICKET_NEW': return NotificationType.ticketNew;
    case 'TICKET_UPDATED': return NotificationType.ticketUpdated;
    case 'SYSTEM':
    default: return NotificationType.system;
  }
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
