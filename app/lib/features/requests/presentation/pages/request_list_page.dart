import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/leave_request_model.dart';
import '../bloc/leave/leave_bloc.dart';
import '../bloc/leave/leave_event.dart';
import '../bloc/leave/leave_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});
  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage>
    with SingleTickerProviderStateMixin {
  late TabController _statusTab;
  String _typeFilter = 'all';

  final _statusTabs = <({RequestStatus? key, String label})>[
    (key: null, label: 'Tất cả'),
    (key: RequestStatus.pending, label: 'Chờ duyệt'),
    (key: RequestStatus.approved, label: 'Đã duyệt'),
    (key: RequestStatus.rejected, label: 'Từ chối'),
    (key: RequestStatus.cancelled, label: 'Đã huỷ'),
  ];
  final _typeFilters = <({String key, String label})>[
    (key: 'all', label: 'Tất cả'),
    (key: 'leave', label: 'Nghỉ phép'),
    (key: 'special', label: 'Đặc biệt'),
  ];

  @override
  void initState() {
    super.initState();
    _statusTab = TabController(length: _statusTabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<LeaveBloc>().add(LoadLeaveRequests()));
  }

  @override
  void dispose() {
    _statusTab.dispose();
    super.dispose();
  }

  IconData _typeIcon(LeaveType type) {
    if (type == LeaveType.latePermission) return Icons.watch_later_outlined;
    if (type == LeaveType.earlyLeaveRequest) return Icons.exit_to_app_rounded;
    if (type == LeaveType.onlineWork) return Icons.laptop_rounded;
    if (type == LeaveType.shiftChange) return Icons.swap_horiz_rounded;
    if (type == LeaveType.annualLeave || type == LeaveType.sickLeave) {
      return Icons.beach_access_outlined;
    }
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      // Sub-nav links
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s16,
          AppTokens.s12,
          AppTokens.s16,
          0,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _NavLink('Xin nghỉ', Icons.beach_access_outlined,
                () => context.go('/leave'), isDark),
            const SizedBox(width: AppTokens.s8),
            _NavLink('Tăng ca', Icons.timer_outlined,
                () => context.go('/overtime'), isDark),
            const SizedBox(width: AppTokens.s8),
            _NavLink('Chấm công lại', Icons.edit_calendar_outlined,
                () => context.go('/attendance-correction'), isDark),
          ]),
        ),
      ),
      const SizedBox(height: AppTokens.s8),
      // Type filter chips
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
          children: _typeFilters
              .map<Widget>((f) => GestureDetector(
                    onTap: () => setState(() => _typeFilter = f.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: AppTokens.s8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _typeFilter == f.key
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTokens.rMicro),
                        border: Border.all(
                            color: _typeFilter == f.key
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder)),
                      ),
                      child: Text(f.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  _typeFilter == f.key ? Colors.white : null)),
                    ),
                  ))
              .toList(),
        ),
      ),
      // Status tabs
      TabBar(
        controller: _statusTab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: _statusTabs.map((t) => Tab(text: t.label)).toList(),
      ),
      Expanded(
          child:
              BlocConsumer<LeaveBloc, LeaveState>(listener: (context, state) {
        if (state is LeaveActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success));
        } else if (state is LeaveError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: AppColors.error));
        }
      }, builder: (context, state) {
        if (state is LeaveLoading || state is LeaveInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is LeaveLoaded) {
          return AnimatedBuilder(
              animation: _statusTab,
              builder: (_, __) {
                var list = state.byType(_typeFilter);
                final statusKey = _statusTabs[_statusTab.index].key;
                if (statusKey != null) {
                  list = list.where((r) => r.status == statusKey).toList();
                }

                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inbox_rounded, title: 'Không có yêu cầu nào');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _RequestCard(
                    request: list[i],
                    isDark: isDark,
                    icon: _typeIcon(list[i].leaveType),
                    onCancel: () => _cancelRequest(context, list[i].id),
                  ),
                );
              });
        }
        return const SizedBox.shrink();
      })),
    ]);
  }

  Future<void> _cancelRequest(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Huỷ yêu cầu?', style: TextStyle(fontSize: 16)),
              content: const Text('Bạn có chắc chắn muốn huỷ đơn này không?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Không')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Huỷ đơn',
                        style: TextStyle(color: Colors.white))),
              ],
            ));
    if (confirm == true && context.mounted) {
      context.read<LeaveBloc>().add(CancelLeaveRequest(id));
    }
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _NavLink(this.label, this.icon, this.onTap, this.isDark);

  @override
  Widget build(BuildContext ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s12, vertical: AppTokens.s8),
              child: Row(children: [
                Icon(icon, size: 16, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: AppTokens.s8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

class _RequestCard extends StatelessWidget {
  final LeaveRequestModel request;
  final bool isDark;
  final IconData icon;
  final VoidCallback onCancel;
  const _RequestCard(
      {required this.request,
      required this.isDark,
      required this.icon,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTokens.rInput),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(request.leaveType.label,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppTokens.s4),
                    Text(
                        request.shiftChangeDate != null &&
                                request.shiftChangeDate!.isNotEmpty
                            ? 'Nghỉ ${request.shiftChangeDate} → Bù ${request.fromDate}'
                            : (request.leaveType == LeaveType.latePermission ||
                                    request.leaveType ==
                                        LeaveType.earlyLeaveRequest
                                ? request.fromDate
                                : '${request.fromDate} → ${request.toDate}'),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppTokens.s8),
                    Row(children: [
                      StatusBadge.requestStatus(request.status.label),
                      const Spacer(),
                      Text(DateFormat('dd/MM/yyyy').format(request.createdAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 11)),
                    ]),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTokens.rCard)),
          ),
          child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(AppTokens.s24),
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppTokens.s16),
                Text(request.leaveType.label,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppTokens.s12),
                StatusBadge.requestStatus(request.status.label),
                const SizedBox(height: AppTokens.s16),
                if (request.shiftChangeDate != null &&
                    request.shiftChangeDate!.isNotEmpty) ...[
                  _Row('Ngày nghỉ (ca cũ)', request.shiftChangeDate!),
                  _Row('Ngày bù (ca mới)', request.fromDate),
                ] else ...[
                  _Row('Từ ngày', request.fromDate),
                  if (request.leaveType != LeaveType.latePermission &&
                      request.leaveType != LeaveType.earlyLeaveRequest)
                    _Row('Đến ngày', request.toDate),
                ],
                if (request.totalDays > 0)
                  _Row('Số ngày', '${request.totalDays}'),
                if (request.leaveType == LeaveType.latePermission &&
                    request.startTime != null)
                  _Row('Giờ đến dự kiến', request.startTime!),
                if (request.leaveType == LeaveType.earlyLeaveRequest &&
                    request.startTime != null)
                  _Row('Giờ về dự kiến', request.startTime!),
                if (request.leaveType == LeaveType.shiftChange) ...[
                  if (request.startTime != null)
                    _Row('Giờ bắt đầu ca', request.startTime!),
                  if (request.endTime != null)
                    _Row('Giờ kết thúc ca', request.endTime!),
                ],
                _Row('Lý do', request.reason),
                if (request.approverName != null &&
                    request.approverName!.isNotEmpty)
                  _Row('Người duyệt', request.approverName!),
                if (request.rejectReason != null) ...[
                  const SizedBox(height: AppTokens.s8),
                  Container(
                      padding: const EdgeInsets.all(AppTokens.s12),
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTokens.rMicro)),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: AppTokens.s8),
                            Expanded(
                                child: Text(
                                    'Lý do từ chối: ${request.rejectReason}',
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.error))),
                          ])),
                ],
                const SizedBox(height: AppTokens.s24),
                // Cancel button
                if (request.status == RequestStatus.pending) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onCancel();
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Huỷ yêu cầu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppTokens.s12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.rInput),
                      ),
                    ),
                  ),
                ],
              ]),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext ctx) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 110,
            child: Text('$label:', style: Theme.of(ctx).textTheme.bodySmall)),
        Expanded(child: Text(value, style: Theme.of(ctx).textTheme.bodyMedium)),
      ]));
}
