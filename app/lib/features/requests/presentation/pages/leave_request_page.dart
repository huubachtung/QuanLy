import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/leave_request_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/leave/leave_bloc.dart';
import '../bloc/leave/leave_event.dart';
import '../bloc/leave/leave_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';

String _formatDays(num? val) {
  if (val == null) return '0';
  if (val % 1 == 0) return val.toInt().toString();
  return val.toString();
}

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});
  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<LeaveBloc>().add(LoadLeaveRequests()));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    UserModel? user;
    if (authState is AuthAuthenticated) user = authState.user as UserModel;
    if (user == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaveState = context.watch<LeaveBloc>().state;

    final availableAnnual = leaveState is LeaveLoaded
        ? (leaveState.annualLeaveBalance - leaveState.pendingDeducts).clamp(0.0, leaveState.annualMaxDays)
        : 12.0;

    // Build stats list from LeaveLoaded.stats or fallback to user.leaveBalances
    List<LeaveStatItem> statsList = [];
    if (leaveState is LeaveLoaded && leaveState.stats.isNotEmpty) {
      statsList = leaveState.stats.values
          .where((s) => !s.isSpecialRequest && s.leaveType != 'OTHER')
          .toList();
    } else {
      statsList = user.leaveBalances
          .where((lb) =>
              lb.leaveType != 'PREVIOUS_YEAR_LEAVE' &&
              lb.leaveType != 'OTHER' &&
              lb.label != 'Lý do khác')
          .map((lb) => LeaveStatItem(
                leaveType: lb.leaveType,
                label: lb.label,
                deductsLeave: lb.leaveType == 'ANNUAL_LEAVE',
                max: lb.totalDays > 12 && lb.leaveType == 'ANNUAL_LEAVE' ? 12 : lb.totalDays,
                approved: lb.usedDays,
                pending: lb.pendingDays,
                remaining: lb.remainingDays,
              ))
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Annual leave balance overview
        Text('Quỹ ngày nghỉ', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Thống kê số ngày đã nghỉ và còn lại của bạn',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600)),
        const SizedBox(height: 14),

        // Annual leave card
        _buildAnnualLeaveCard(context, user, isDark, leaveState),
        const SizedBox(height: 16),

        // Detailed leave stats table
        _LeaveStatsTable(stats: statsList, isDark: isDark),
        const SizedBox(height: 20),

        // Create request button
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateSheet(context, isDark, user!, availableAnnual),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Tạo đơn mới'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
        const SizedBox(height: 20),

        // Recent requests
        Row(children: [
          Text('Đơn gần đây', style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/requests'),
            child: const Text('Xem tất cả →', style: TextStyle(fontSize: 12)),
          ),
        ]),
        if (leaveState is LeaveLoading || leaveState is LeaveInitial)
          const Center(child: CircularProgressIndicator())
        else if (leaveState is LeaveLoaded) ...[
          if (leaveState.requests.isEmpty)
            const EmptyState(
                icon: Icons.inbox_rounded, title: 'Chưa có đơn nào')
          else
            Column(
                children: leaveState.requests
                    .take(3)
                    .map((r) => _RequestCard(request: r, isDark: isDark))
                    .toList())
        ],
      ]),
    );
  }

  Widget _buildAnnualLeaveCard(
      BuildContext context, UserModel user, bool isDark, LeaveState leaveState) {
    double totalDays = 12.0;
    double usedDays = 0.0;
    double remaining = 12.0;
    double pendingDays = 0.0;

    if (leaveState is LeaveLoaded) {
      totalDays = leaveState.annualMaxDays;
      remaining = leaveState.annualLeaveBalance;
      pendingDays = leaveState.pendingDeducts;
      final annualStat = leaveState.stats['ANNUAL_LEAVE'];
      if (annualStat != null) {
        usedDays = annualStat.approved;
        totalDays = annualStat.max;
        remaining = annualStat.remaining ?? leaveState.annualLeaveBalance;
        pendingDays = annualStat.pending;
      }
    } else {
      final annualBalance = user.leaveBalances.firstWhere(
        (lb) => lb.leaveType == 'ANNUAL_LEAVE',
        orElse: () => const LeaveBalanceModel(
            leaveType: 'ANNUAL_LEAVE',
            label: 'Phép năm',
            totalDays: 12,
            usedDays: 0),
      );
      totalDays = 12.0;
      usedDays = annualBalance.usedDays;
      remaining = annualBalance.remainingDays > 12 ? 12 : annualBalance.remainingDays;
      pendingDays = annualBalance.pendingDays;
    }

    Color badgeColor;
    String badgeLabel;
    if (remaining <= 0) {
      badgeColor = AppColors.error;
      badgeLabel = 'Hết phép';
    } else if (remaining <= 2 || remaining <= totalDays * 0.2) {
      badgeColor = AppColors.warning;
      badgeLabel = 'Sắp hết';
    } else {
      badgeColor = AppColors.success;
      badgeLabel = 'Còn nhiều';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, Color(0xFF1E4A9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Phép năm',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          StatusBadge(
              label: badgeLabel, color: badgeColor, textColor: badgeColor),
          if (pendingDays > 0) ...[
            const SizedBox(width: 8),
            StatusBadge(
                label: '+${_formatDays(pendingDays)} chờ duyệt',
                color: AppColors.gold),
          ],
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatDays(remaining),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('/ ${_formatDays(totalDays)} ngày',
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _LeaveStatChip('Đã dùng', _formatDays(usedDays),
              Colors.white.withValues(alpha: 0.25)),
          const SizedBox(width: 8),
          _LeaveStatChip(
              'Còn lại', _formatDays(remaining), Colors.white.withValues(alpha: 0.25)),
          const SizedBox(width: 8),
          if (pendingDays > 0)
            _LeaveStatChip('Chờ duyệt', _formatDays(pendingDays),
                AppColors.gold.withValues(alpha: 0.3)),
        ]),
      ]),
    );
  }

  void _showCreateSheet(
      BuildContext context, bool isDark, UserModel user, double availableAnnual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LeaveBloc>(),
        child: _CreateLeaveSheet(
          isDark: isDark,
          user: user,
          availableAnnualLeave: availableAnnual,
        ),
      ),
    );
  }
}

class _LeaveStatChip extends StatelessWidget {
  final String label, value;
  final Color bg;
  const _LeaveStatChip(this.label, this.value, this.bg);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );
}

class _LeaveStatsTable extends StatelessWidget {
  final List<LeaveStatItem> stats;
  final bool isDark;

  const _LeaveStatsTable({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final headerBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: headerBg,
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Loại đơn',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 42,
                  child: Text('Tổng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 58,
                  child: Text('Đã duyệt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 58,
                  child: Text('Đang chờ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 50,
                  child: Text('Còn lại',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
            itemBuilder: (ctx, i) {
              final s = stats[i];
              final isExhausted = s.remaining != null && s.remaining! <= 0;
              final isAlmostOut =
                  s.remaining != null && s.remaining! > 0 && s.remaining! <= 2;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Loại đơn + Phụ đề
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.label,
                                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                ),
                              ),
                              if (isExhausted && s.max == 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Hết',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ] else if (isAlmostOut) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Sắp hết',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.deductsLeave ? 'Trừ phép tháng' : 'Không trừ phép tháng',
                            style: TextStyle(
                              fontSize: 11,
                              color: s.deductsLeave
                                  ? (isDark ? Colors.blue.shade300 : AppColors.primaryBlue)
                                  : (isDark ? Colors.white38 : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tổng
                    SizedBox(
                      width: 42,
                      child: Text(
                        _formatDays(s.max),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    // Đã duyệt
                    SizedBox(
                      width: 58,
                      child: Text(
                        _formatDays(s.approved),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    // Đang chờ
                    SizedBox(
                      width: 58,
                      child: Text(
                        _formatDays(s.pending),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: s.pending > 0 ? AppColors.gold : Colors.grey,
                          fontWeight: s.pending > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Còn lại
                    SizedBox(
                      width: 50,
                      child: Text(
                        s.remaining != null ? _formatDays(s.remaining) : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: s.remaining == null
                              ? Colors.grey
                              : (s.remaining! <= 0 ? AppColors.error : AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final LeaveRequestModel request;
  final bool isDark;
  const _RequestCard({required this.request, required this.isDark});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.leaveType.label,
              style: Theme.of(ctx).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${request.fromDate} → ${request.toDate}',
              style: Theme.of(ctx).textTheme.bodySmall),
        ])),
        StatusBadge.requestStatus(request.status.label),
      ]),
    );
  }
}

// ── Create Leave Sheet ─────────────────────────────────────────
class _CreateLeaveSheet extends StatefulWidget {
  final bool isDark;
  final UserModel user;
  final double availableAnnualLeave;
  const _CreateLeaveSheet({
    required this.isDark,
    required this.user,
    required this.availableAnnualLeave,
  });
  @override
  State<_CreateLeaveSheet> createState() => _CreateLeaveSheetState();
}

class _CreateLeaveSheetState extends State<_CreateLeaveSheet> {
  String _group = 'leave'; // 'leave' or 'special'
  LeaveType _selectedType = LeaveType.annualLeave;
  LeaveDuration _duration = LeaveDuration.fullDay;
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _toDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String _lateTime = '09:30';
  String _earlyTime = '16:30';
  String _shiftStartTime = '08:30';
  String _shiftEndTime = '';
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  List<LeaveType> get _leaveTypes => _group == 'leave'
      ? [
          LeaveType.annualLeave,
          LeaveType.previousYearLeave,
          LeaveType.compensatoryLeave,
          LeaveType.sickLeave,
          LeaveType.summerLeave,
          LeaveType.unpaidLeave,
          LeaveType.marriageLeave,
          LeaveType.bereavementLeave,
          LeaveType.wifeBirthSingleNormal
        ]
      : [
          LeaveType.shiftChange,
          LeaveType.onlineWork,
          LeaveType.latePermission,
          LeaveType.earlyLeaveRequest
        ];

  bool get _isTimeInput =>
      _selectedType == LeaveType.latePermission ||
      _selectedType == LeaveType.earlyLeaveRequest ||
      _selectedType == LeaveType.shiftChange;

  String? get _computedStartTime {
    if (_selectedType == LeaveType.shiftChange) return _shiftStartTime;
    if (_selectedType == LeaveType.latePermission)
      return widget.user.workStartTime;
    if (_selectedType == LeaveType.earlyLeaveRequest) return _earlyTime;
    switch (_duration) {
      case LeaveDuration.morning:
      case LeaveDuration.fullDay:
        return widget.user.workStartTime;
      case LeaveDuration.afternoon:
        return '13:30';
    }
  }

  String? get _computedEndTime {
    if (_selectedType == LeaveType.shiftChange)
      return _shiftEndTime.isNotEmpty ? _shiftEndTime : null;
    if (_selectedType == LeaveType.latePermission) return _lateTime;
    if (_selectedType == LeaveType.earlyLeaveRequest)
      return widget.user.workEndTime;
    switch (_duration) {
      case LeaveDuration.afternoon:
      case LeaveDuration.fullDay:
        return widget.user.workEndTime;
      case LeaveDuration.morning:
        return '12:00';
    }
  }

  double _calculateWorkingDays(
      DateTime start, DateTime end, LeaveDuration duration) {
    if (duration == LeaveDuration.morning ||
        duration == LeaveDuration.afternoon) return 0.5;
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    if (s.isAfter(e)) return 0;

    int count = 0;
    DateTime cur = s;
    while (!cur.isAfter(e)) {
      if (cur.weekday != DateTime.sunday) {
        // Sunday is 7 in Dart
        count++;
      }
      cur = DateTime(cur.year, cur.month, cur.day + 1);
    }
    return count.toDouble();
  }

  void _submit() {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng nhập lý do'),
          backgroundColor: AppColors.error));
      return;
    }

    // Auto-adjust dates
    DateTime effectiveToDate = _toDate;
    if (_selectedType.isSpecialRequest || _duration != LeaveDuration.fullDay) {
      effectiveToDate = _fromDate;
    }

    // Auto-adjust duration
    LeaveDuration effectiveDuration = _duration;
    if (!_selectedType.isSpecialRequest &&
        (_fromDate.year != effectiveToDate.year ||
            _fromDate.month != effectiveToDate.month ||
            _fromDate.day != effectiveToDate.day)) {
      effectiveDuration = LeaveDuration.fullDay;
    }

    final totalDays = _isTimeInput
        ? 0.0
        : _calculateWorkingDays(_fromDate, effectiveToDate, effectiveDuration);

    if (_selectedType.deductsAnnualLeave && totalDays > 0) {
      if (totalDays > widget.availableAnnualLeave) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Không đủ phép. Khả dụng: ${_formatDays(widget.availableAnnualLeave)} ngày (đã trừ ngày chờ duyệt)'),
            backgroundColor: AppColors.error));
        return;
      }
    }

    final request = LeaveRequestModel(
      id: 'leave_new_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      employeeCode: widget.user.employeeCode ?? '',
      fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
      toDate: DateFormat('yyyy-MM-dd').format(effectiveToDate),
      totalDays: totalDays,
      leaveType: _selectedType,
      leaveDuration: effectiveDuration,
      startTime: _computedStartTime,
      endTime: _computedEndTime,
      reason: _reasonCtrl.text.trim(),
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
    context.read<LeaveBloc>().add(CreateLeaveRequest(request));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeaveBloc, LeaveState>(listener: (context, state) {
      if (state is LeaveActionSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message), backgroundColor: AppColors.success));
      } else if (state is LeaveError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message), backgroundColor: AppColors.error));
      }
    }, builder: (context, state) {
      final submitting = state is LeaveLoading;
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Tạo đơn mới',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                // Group selector
                Row(children: [
                  Expanded(
                      child: _GroupBtn(
                          'Xin nghỉ',
                          'leave',
                          _group == 'leave',
                          () => setState(() {
                                _group = 'leave';
                                _selectedType = LeaveType.annualLeave;
                                if (_duration != LeaveDuration.fullDay)
                                  _toDate = _fromDate;
                              }))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _GroupBtn(
                          'Đơn đặc biệt',
                          'special',
                          _group == 'special',
                          () => setState(() {
                                _group = 'special';
                                _selectedType = LeaveType.shiftChange;
                                _toDate = _fromDate;
                                _duration = LeaveDuration.fullDay;
                              }))),
                ]),
                const SizedBox(height: 16),
                // Type selector
                Text('Loại đơn', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _leaveTypes
                        .map((t) => GestureDetector(
                            onTap: () => setState(() {
                                  _selectedType = t;
                                  if (t.isSpecialRequest) {
                                    _toDate = _fromDate;
                                    _duration = LeaveDuration.fullDay;
                                  }
                                }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: _selectedType == t
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _selectedType == t
                                        ? AppColors.primaryBlue
                                        : (widget.isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder)),
                              ),
                              child: Text(t.label,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedType == t
                                          ? Colors.white
                                          : null)),
                            )))
                        .toList()),
                const SizedBox(height: 16),
                // Date / Time fields
                if (!_isTimeInput) ...[
                  Row(children: [
                    Expanded(
                        child: _DateField(
                            'Từ ngày',
                            _fromDate,
                            (d) => setState(() {
                                  _fromDate = d;
                                  if (_toDate.isBefore(d) ||
                                      _duration != LeaveDuration.fullDay ||
                                      _selectedType.isSpecialRequest) {
                                    _toDate = d;
                                  }
                                }))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _DateField(
                            'Đến ngày',
                            _toDate,
                            (d) => setState(() {
                                  _toDate = d;
                                  if (_toDate.isAfter(_fromDate)) {
                                    _duration = LeaveDuration.fullDay;
                                  }
                                }))),
                  ]),
                  const SizedBox(height: 12),
                  if (!_selectedType.isSpecialRequest ||
                      _selectedType == LeaveType.onlineWork) ...[
                    Text('Thời lượng',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                        children: LeaveDuration.values
                            .map((d) => Expanded(
                                child: GestureDetector(
                                    onTap: () => setState(() {
                                          _duration = d;
                                          if (d != LeaveDuration.fullDay)
                                            _toDate = _fromDate;
                                        }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _duration == d
                                            ? AppColors.primaryBlue
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: _duration == d
                                                ? AppColors.primaryBlue
                                                : (widget.isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)),
                                      ),
                                      child: Text(d.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _duration == d
                                                  ? Colors.white
                                                  : null)),
                                    ))))
                            .toList()),
                    const SizedBox(height: 12),
                  ],
                ] else ...[
                  _DateField(
                      'Ngày', _fromDate, (d) => setState(() => _fromDate = d)),
                  const SizedBox(height: 12),
                  if (_selectedType == LeaveType.shiftChange) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('shiftStart'),
                            initialValue: _shiftStartTime,
                            keyboardType: TextInputType.datetime,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Giờ bắt đầu (HH:mm)',
                              prefixIcon:
                                  Icon(Icons.access_time_rounded, size: 18),
                            ),
                            onChanged: (v) => _shiftStartTime = v,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('shiftEnd'),
                            initialValue: _shiftEndTime,
                            keyboardType: TextInputType.datetime,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Giờ kết thúc (Tuỳ chọn)',
                              prefixIcon:
                                  Icon(Icons.access_time_rounded, size: 18),
                            ),
                            onChanged: (v) => _shiftEndTime = v,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    TextFormField(
                      key: ValueKey(_selectedType),
                      initialValue: _selectedType == LeaveType.latePermission
                          ? _lateTime
                          : _earlyTime,
                      keyboardType: TextInputType.datetime,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: _selectedType == LeaveType.latePermission
                            ? 'Giờ đi muộn dự kiến (HH:mm)'
                            : 'Giờ về sớm dự kiến (HH:mm)',
                        prefixIcon:
                            const Icon(Icons.access_time_rounded, size: 18),
                      ),
                      onChanged: (v) {
                        if (_selectedType == LeaveType.latePermission) {
                          _lateTime = v;
                        } else {
                          _earlyTime = v;
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                      labelText: 'Lý do *', alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                if (!_isTimeInput)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Số ngày nghỉ (trừ CN): ${_calculateWorkingDays(_fromDate, _duration != LeaveDuration.fullDay ? _fromDate : _toDate, _duration)} ngày',
                            style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Gửi đơn',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                    )),
              ]),
        ),
      );
    });
  }
}

class _GroupBtn extends StatelessWidget {
  final String groupLabel;
  final String groupKey;
  final bool selected;
  final VoidCallback onTap;
  const _GroupBtn(this.groupLabel, this.groupKey, this.selected, this.onTap);
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primaryBlue : AppColors.darkBorder),
          ),
          child: Center(
              child: Text(groupLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : null),
                  textAlign: TextAlign.center)),
        ),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateField(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
              context: ctx,
              initialDate: value,
              firstDate: DateTime(2024),
              lastDate: DateTime(2028));
          if (d != null) onChanged(d);
        },
        child: AbsorbPointer(
            child: TextFormField(
          key: ValueKey(value),
          initialValue: DateFormat('dd/MM/yyyy').format(value),
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          ),
        )),
      );
}
