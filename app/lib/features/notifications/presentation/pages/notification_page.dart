import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../../../shared/widgets/empty_state.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = <({String key, String label})>[
    (key: 'all', label: 'Tất cả'),
    (key: 'unread', label: 'Chưa đọc'),
    (key: 'task', label: 'Task'),
    (key: 'leave', label: 'Nghỉ phép'),
    (key: 'ot', label: 'Tăng ca'),
    (key: 'system', label: 'Hệ thống'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(LoadNotifications());
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Widget _buildNotifIcon(NotificationType type, Color color) {
    String? assetPath;
    IconData? iconData;

    switch (type) {
      case NotificationType.taskDeadline:
        assetPath = 'assets/images/task.png';
        break;
      case NotificationType.otRejected:
        assetPath = 'assets/images/timer.png';
        break;
      case NotificationType.projectAssigned:
        assetPath = 'assets/images/project.png';
        break;
      case NotificationType.system:
        assetPath = 'assets/images/sys_update.png';
        break;
      case NotificationType.leaveRejected:
        assetPath = 'assets/images/vacation.png';
        break;
      case NotificationType.taskAssigned:
      case NotificationType.taskTransferRequest:
      case NotificationType.taskTransferApproved:
      case NotificationType.taskTransferRejected:
        assetPath = 'assets/images/task.png';
        break;
      case NotificationType.leaveRequest:
      case NotificationType.leaveApproved:
        assetPath = 'assets/images/vacation.png';
        break;
      case NotificationType.otRequest:
      case NotificationType.otApproved:
        assetPath = 'assets/images/timer.png';
        break;
      default:
        iconData = Icons.notifications_rounded;
        break;
    }

    if (assetPath != null) {
      return Center(
          child: Image.asset(assetPath, width: 20, height: 20, color: color));
    }
    return Icon(iconData, color: color, size: 20);
  }

  Color _notifColor(NotificationType type) {
    switch (type) {
      case NotificationType.leaveApproved:
      case NotificationType.otApproved:
      case NotificationType.taskTransferApproved:
        return AppColors.success;
      case NotificationType.leaveRejected:
      case NotificationType.otRejected:
      case NotificationType.taskTransferRejected:
        return AppColors.error;
      case NotificationType.taskDeadline:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.info;
      default:
        return AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        }
        
        return Column(children: [
          // Mark all read
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Text('$unreadCount chưa đọc',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllNotificationsRead());
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('Đánh dấu tất cả đã đọc',
                      style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          // Tab bar
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabs.map((t) {
              final count = t.key == 'unread' ? unreadCount : 0;
              return Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.label),
                if (t.key == 'unread' && count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]));
            }).toList(),
          ),
          Expanded(
            child: (state is NotificationLoading || state is NotificationInitial)
            ? const Center(child: CircularProgressIndicator())
            : (state is NotificationLoaded)
            ? AnimatedBuilder(
              animation: _tabCtrl,
              builder: (_, __) {
                final list = state.byFilter(_tabs[_tabCtrl.index].key);
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.notifications_off_rounded,
                      title: 'Không có thông báo');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final n = list[i];
                    final color = _notifColor(n.type);
                    return GestureDetector(
                      onTap: () => _onTap(context, n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                              : (isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.primaryBlue.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: n.isRead
                                ? (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)
                                : color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10)),
                                child: _buildNotifIcon(n.type, color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(n.title,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: n.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.color),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis)),
                                      if (!n.isRead)
                                        Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: AppColors.error,
                                                shape: BoxShape.circle)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(n.body,
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      if (n.senderName != null) ...[
                                        Icon(Icons.person_outline_rounded,
                                            size: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.color),
                                        const SizedBox(width: 3),
                                        Text(n.senderName!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(_formatTime(n.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall),
                                    ]),
                                  ])),
                            ]),
                      ),
                    );
                  },
                );
              },
            )
            : const SizedBox.shrink()
          ),
        ]);
      }
    );
  }

  void _onTap(BuildContext context, NotificationModel n) {
    if (!n.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationRead(n.id));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(n.title, style: const TextStyle(fontSize: 15)),
        content: Text(n.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng')),
          if (n.type == NotificationType.taskAssigned ||
              n.type == NotificationType.taskDeadline)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  context.go('/projects');
                }
              },
              child: const Text('Xem Task'),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}
