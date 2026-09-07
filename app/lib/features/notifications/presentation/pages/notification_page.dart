import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
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
      context.read<NotificationBloc>().add(const LoadNotifications());
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
      case NotificationType.taskAssigned:
      case NotificationType.taskTransferRequest:
      case NotificationType.taskTransferApproved:
      case NotificationType.taskTransferRejected:
        assetPath = 'assets/images/task.png';
        break;
      case NotificationType.projectAssigned:
        assetPath = 'assets/images/project.png';
        break;
      case NotificationType.leaveRequest:
      case NotificationType.leaveApproved:
      case NotificationType.leaveRejected:
        assetPath = 'assets/images/vacation.png';
        break;
      case NotificationType.otRequest:
      case NotificationType.otApproved:
      case NotificationType.otRejected:
        assetPath = 'assets/images/timer.png';
        break;
      case NotificationType.system:
        assetPath = 'assets/images/sys_update.png';
        break;
      default:
        iconData = Icons.notifications_rounded;
        break;
    }

    if (assetPath != null) {
      return Center(
        child: Image.asset(assetPath, width: 20, height: 20, color: color),
      );
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
        return AppColors.primaryBlue;
    }
  }

  String _getEmptyMessage(String tabKey) {
    switch (tabKey) {
      case 'unread':
        return 'Không có thông báo chưa đọc';
      case 'task':
        return 'Không có thông báo công việc nào';
      case 'leave':
        return 'Không có thông báo nghỉ phép nào';
      case 'ot':
        return 'Không có thông báo tăng ca nào';
      case 'system':
        return 'Không có thông báo hệ thống nào';
      default:
        return 'Bạn chưa có thông báo nào';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;
              if (unreadCount <= 0) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () {
                  context.read<NotificationBloc>().add(MarkAllNotificationsRead());
                },
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          if (state is NotificationLoaded) {
            unreadCount = state.unreadCount;
          }

          return Column(
            children: [
              // Unread summary banner
              if (unreadCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    AppTokens.s8,
                    AppTokens.s16,
                    AppTokens.s4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s12,
                    vertical: AppTokens.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(AppTokens.rInput),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined,
                          size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: AppTokens.s8),
                      Text(
                        'Bạn có $unreadCount thông báo chưa đọc',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab bar
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _tabs.map((t) {
                  final count = t.key == 'unread' ? unreadCount : 0;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.label),
                        if (t.key == 'unread' && count > 0) ...[
                          const SizedBox(width: AppTokens.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(AppTokens.rMicro),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Content
              Expanded(
                child: _buildContent(context, state, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationState state,
    bool isDark,
  ) {
    if (state is NotificationLoading || state is NotificationInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppTokens.s12),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTokens.s16),
              ElevatedButton.icon(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is NotificationLoaded) {
      return AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) {
          final list = state.byFilter(_tabs[_tabCtrl.index].key);

          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications(isRefresh: true));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: _getEmptyMessage(_tabs[_tabCtrl.index].key),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<NotificationBloc>()
                  .add(const LoadNotifications(isRefresh: true));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (ctx, i) {
                final n = list[i];
                final color = _notifColor(n.type);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16,
                    vertical: AppTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: n.isRead
                        ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                        : (isDark
                            ? AppColors.darkCardElevated
                            : AppColors.primaryBlue.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    border: Border.all(
                      color: n.isRead
                          ? (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)
                          : color.withValues(alpha: 0.35),
                      width: n.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTokens.rCard),
                      onTap: () => _onTap(context, n),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.s16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTokens.rInput),
                              ),
                              child: _buildNotifIcon(n.type, color),
                            ),
                            const SizedBox(width: AppTokens.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: n.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w700,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!n.isRead) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.s4),
                                  Text(
                                    n.body,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: n.isRead
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.8)
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppTokens.s8),
                                  Row(
                                    children: [
                                      if (n.senderName != null &&
                                          n.senderName!.isNotEmpty) ...[
                                        Icon(Icons.person_outline_rounded,
                                            size: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.color),
                                        const SizedBox(width: AppTokens.s4),
                                        Text(
                                          n.senderName!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        const SizedBox(width: AppTokens.s8),
                                      ],
                                      Icon(Icons.access_time_rounded,
                                          size: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.color),
                                      const SizedBox(width: AppTokens.s4),
                                      Text(
                                        _formatTime(n.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      if (n.link.isNotEmpty) ...[
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 11,
                                          color: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.color
                                              ?.withValues(alpha: 0.6),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _onTap(BuildContext context, NotificationModel n) {
    if (!n.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationRead(n.id));
    }

    final link = n.link.trim();
    if (link.isNotEmpty) {
      try {
        context.push(link);
        return;
      } catch (e) {
        debugPrint('Direct push error for $link: $e');
      }
    }

    _showNotificationDetails(context, n);
  }

  void _showNotificationDetails(BuildContext context, NotificationModel n) {
    final color = _notifColor(n.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildNotifIcon(n.type, color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(n.createdAt),
                            style: Theme.of(bottomSheetContext)
                                .textTheme
                                .labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(bottomSheetContext)
                        .cardColor
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    n.body,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ),
                if (n.senderName != null && n.senderName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Người gửi: ${n.senderName}',
                    style: Theme.of(bottomSheetContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        child: const Text('Đóng'),
                      ),
                    ),
                    if (n.link.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            if (context.mounted) {
                              context.push(n.link);
                            }
                          },
                          child: const Text('Xem chi tiết'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}
