import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
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

    // Canonical leave types order matching the real HR system
    const canonicalLeaveOrder = [
      'ANNUAL_LEAVE',
      'COMPENSATORY_LEAVE',
      'SICK_LEAVE',
      'SUMMER_LEAVE',
      'MARRIAGE_LEAVE',
      'BEREAVEMENT_LEAVE',
      'WIFE_BIRTH_SINGLE_NORMAL',
      'WIFE_BIRTH_SINGLE_SURGERY',
      'WIFE_BIRTH_TWINS_NORMAL',
      'WIFE_BIRTH_TRIPLETS_NORMAL',
      'WIFE_BIRTH_TWINS_SURGERY',
      'ADOPTION_UNDER_6M',
      'CONTRACEPTION_LEAVE',
      'RECOVERY_LEAVE',
      'HOLIDAYS_FOR_EXPATS',
      'MILITARY_LEAVE',
      'WIFE_MISCARRIAGE_OVER_22W',
      'UNPAID_LEAVE',
    ];

    // Build stats list from LeaveLoaded.stats or fallback to user.leaveBalances
    List<LeaveStatItem> statsList = [];
    if (leaveState is LeaveLoaded && leaveState.stats.isNotEmpty) {
      statsList = leaveState.stats.values
          .where((s) =>
              !s.isSpecialRequest &&
              s.leaveType != 'OTHER' &&
              s.leaveType != 'PREVIOUS_YEAR_LEAVE')
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
                max: lb.totalDays,
                approved: lb.usedDays,
                pending: lb.pendingDays,
                remaining: lb.remainingDays,
              ))
          .toList();
    }

    // Sort according to canonical list
    statsList.sort((a, b) {
      final idxA = canonicalLeaveOrder.indexOf(a.leaveType);
      final idxB = canonicalLeaveOrder.indexOf(b.leaveType);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.label.compareTo(b.label);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Annual leave balance overview
        Text('Quỹ ngày nghỉ', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTokens.s4),
        Text('Thống kê số ngày đã nghỉ và còn lại của bạn',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600)),
        const SizedBox(height: AppTokens.s12),

        // Annual leave card
        _buildAnnualLeaveCard(context, user, isDark, leaveState),
        const SizedBox(height: AppTokens.s16),

        // Detailed leave stats table
        LeaveStatsTable(stats: statsList, isDark: isDark),
        const SizedBox(height: AppTokens.s16),

        // Create request button
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateSheet(context, isDark, user!, availableAnnual),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Tạo đơn mới'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.rInput),
                  )),
            )),
        const SizedBox(height: AppTokens.s24),

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
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, Color(0xFF1E4A9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTokens.rCard),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Phép năm',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          StatusBadge(
              label: badgeLabel, color: badgeColor, textColor: badgeColor),
          if (pendingDays > 0) ...[
            const SizedBox(width: AppTokens.s8),
            StatusBadge(
                label: '+${_formatDays(pendingDays)} chờ duyệt',
                color: AppColors.gold),
          ],
        ]),
        const SizedBox(height: AppTokens.s12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatDays(remaining),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: AppTokens.s4),
          Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('/ ${_formatDays(totalDays)} ngày',
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ]),
        const SizedBox(height: AppTokens.s12),
        Row(children: [
          _LeaveStatChip('Đã dùng', _formatDays(usedDays),
              Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: AppTokens.s8),
          _LeaveStatChip(
              'Còn lại', _formatDays(remaining), Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: AppTokens.s8),
          if (pendingDays > 0)
            _LeaveStatChip('Chờ duyệt', _formatDays(pendingDays),
                AppColors.gold.withValues(alpha: 0.25)),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s8,
          vertical: AppTokens.s4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTokens.rMicro),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      );
}

class LeaveStatsTable extends StatelessWidget {
  final List<LeaveStatItem> stats;
  final bool isDark;

  const LeaveStatsTable({super.key, required this.stats, required this.isDark});

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
                  child: Text('Loại đơn',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 44,
                  child: Text('Tổng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 56,
                  child: Text('Đã duyệt',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 56,
                  child: Text('Đang chờ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
                SizedBox(
                  width: 56,
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
              final rem = s.remaining ?? (s.max > 0 ? (s.max - s.approved - s.pending) : 0.0);
              final isExhausted = rem <= 0;
              final isAlmostOut = rem > 0 && rem <= 2;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Loại đơn + Phụ đề
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
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
                      width: 44,
                      child: Text(
                        _formatDays(s.max),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    // Đã duyệt
                    SizedBox(
                      width: 56,
                      child: Text(
                        _formatDays(s.approved),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    // Đang chờ
                    SizedBox(
                      width: 56,
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
                    // Còn lại + Badge (Hết / Sắp hết)
                    SizedBox(
                      width: 56,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDays(rem),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isExhausted
                                  ? AppColors.error
                                  : (isAlmostOut ? AppColors.warning : AppColors.success),
                            ),
                          ),
                          if (isExhausted) ...[
                            const SizedBox(height: 2),
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
                            const SizedBox(height: 2),
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
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
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
          const SizedBox(height: AppTokens.s4),
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
  String _shiftChangeMode = 'TIME'; // 'TIME' (cùng ngày) hoặc 'DATE' (khác ngày)
  DateTime? _shiftChangeDate;
  String _lateTime = '09:30';
  String _earlyTime = '16:30';
  String _shiftStartTime = '08:30';
  String _shiftEndTime = '';
  String? _formError;
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  List<LeaveType> get _leaveTypes => _group == 'leave'
      ? [
          LeaveType.annualLeave,
          LeaveType.compensatoryLeave,
          LeaveType.sickLeave,
          LeaveType.summerLeave,
          LeaveType.marriageLeave,
          LeaveType.bereavementLeave,
          LeaveType.wifeBirthSingleNormal,
          LeaveType.wifeBirthSingleSurgery,
          LeaveType.wifeBirthTwinsNormal,
          LeaveType.wifeBirthTriplets,
          LeaveType.wifeBirthTwinsSurgery,
          LeaveType.adoptionUnder6m,
          LeaveType.contraceptionLeave,
          LeaveType.recoveryLeave,
          LeaveType.holidaysForExpats,
          LeaveType.militaryLeave,
          LeaveType.wifeMiscarriageOver22w,
          LeaveType.unpaidLeave,
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
    if (_selectedType == LeaveType.shiftChange) {
      return _shiftStartTime.trim().isNotEmpty ? _shiftStartTime.trim() : null;
    }
    if (_selectedType == LeaveType.latePermission) {
      return _lateTime.trim().isNotEmpty ? _lateTime.trim() : null;
    }
    if (_selectedType == LeaveType.earlyLeaveRequest) {
      return _earlyTime.trim().isNotEmpty ? _earlyTime.trim() : null;
    }
    return null;
  }

  String? get _computedEndTime {
    if (_selectedType == LeaveType.shiftChange) {
      return _shiftEndTime.trim().isNotEmpty ? _shiftEndTime.trim() : null;
    }
    return null;
  }

  double _calculateWorkingDays(
      DateTime start, DateTime end, LeaveDuration duration) {
    if (duration == LeaveDuration.morning ||
        duration == LeaveDuration.afternoon) {
      return 0.5;
    }
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    if (s.isAfter(e)) {
      return 0;
    }

    int count = 0;
    DateTime cur = s;
    while (!cur.isAfter(e)) {
      if (cur.weekday != DateTime.sunday) {
        count++;
      }
      cur = DateTime(cur.year, cur.month, cur.day + 1);
    }
    return count.toDouble();
  }

  void _submit() {
    setState(() => _formError = null);

    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _formError = 'Vui lòng nhập lý do');
      return;
    }

    if (_selectedType == LeaveType.shiftChange &&
        _shiftChangeMode == 'DATE' &&
        _shiftChangeDate == null) {
      setState(() => _formError = 'Vui lòng chọn ngày ca cũ cần xin nghỉ');
      return;
    }

    // Auto-adjust dates
    DateTime effectiveToDate = _toDate;
    if (_selectedType.isSingleDayOnly ||
        _selectedType == LeaveType.shiftChange ||
        _duration != LeaveDuration.fullDay) {
      effectiveToDate = _fromDate;
    }

    // Auto-adjust duration
    LeaveDuration effectiveDuration = _duration;
    if (!_selectedType.isTimeBasedRequest &&
        (_fromDate.year != effectiveToDate.year ||
            _fromDate.month != effectiveToDate.month ||
            _fromDate.day != effectiveToDate.day)) {
      effectiveDuration = LeaveDuration.fullDay;
    }

    final totalDays = _isTimeInput
        ? (_selectedType == LeaveType.shiftChange ? 0.0 : 1.0)
        : _calculateWorkingDays(_fromDate, effectiveToDate, effectiveDuration);

    if (_selectedType.deductsAnnualLeave && totalDays > 0) {
      if (totalDays > widget.availableAnnualLeave) {
        setState(() => _formError =
            'Không đủ phép. Khả dụng: ${_formatDays(widget.availableAnnualLeave)} ngày (đã trừ ngày chờ duyệt)');
        return;
      }
    }

    final request = LeaveRequestModel(
      id: 'leave_new_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      employeeCode: widget.user.employeeCode ?? '',
      fromDate: DateFormat('yyyy-MM-dd').format(_fromDate),
      toDate: DateFormat('yyyy-MM-dd').format(effectiveToDate),
      shiftChangeDate: (_selectedType == LeaveType.shiftChange &&
              _shiftChangeMode == 'DATE' &&
              _shiftChangeDate != null)
          ? DateFormat('yyyy-MM-dd').format(_shiftChangeDate!)
          : null,
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
        setState(() => _formError = state.message);
      }
    }, builder: (context, state) {
      final submitting = state is LeaveLoading;
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.rCard),
            ),
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
                            color: widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: AppTokens.s16),
                Text('Tạo đơn mới',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppTokens.s16),

                // Error Banner
                if (_formError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.s16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.rMicro),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formError!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                          onPressed: () => setState(() => _formError = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],

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
                                _formError = null;
                                if (_duration != LeaveDuration.fullDay) {
                                  _toDate = _fromDate;
                                }
                              }))),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                      child: _GroupBtn(
                          'Đơn đặc biệt',
                          'special',
                          _group == 'special',
                          () => setState(() {
                                _group = 'special';
                                _selectedType = LeaveType.shiftChange;
                                _shiftChangeMode = 'TIME';
                                _shiftChangeDate = null;
                                _formError = null;
                                _toDate = _fromDate;
                                _duration = LeaveDuration.fullDay;
                              }))),
                ]),
                const SizedBox(height: AppTokens.s16),
                // Type selector
                Text('Loại đơn', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppTokens.s8),
                Wrap(
                    spacing: AppTokens.s8,
                    runSpacing: AppTokens.s8,
                    children: _leaveTypes
                        .map((t) => GestureDetector(
                            onTap: () => setState(() {
                                  _selectedType = t;
                                  _formError = null;
                                  if (t.isSingleDayOnly || t == LeaveType.shiftChange) {
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
                                borderRadius: BorderRadius.circular(AppTokens.rMicro),
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
                const SizedBox(height: AppTokens.s16),
                // Date / Time fields
                if (!_isTimeInput) ...[
                  Row(children: [
                    Expanded(
                        child: _DateField(
                            'Từ ngày',
                            _fromDate,
                            (d) => setState(() {
                                  _fromDate = d;
                                  _formError = null;
                                  if (_toDate.isBefore(d) ||
                                      _duration != LeaveDuration.fullDay ||
                                      _selectedType.isSingleDayOnly) {
                                    _toDate = d;
                                  }
                                }))),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                        child: _DateField(
                            'Đến ngày',
                            _toDate,
                            (d) => setState(() {
                                  _toDate = d;
                                  _formError = null;
                                  if (_toDate.isAfter(_fromDate)) {
                                    _duration = LeaveDuration.fullDay;
                                  }
                                }))),
                  ]),
                  const SizedBox(height: AppTokens.s12),
                  Text('Thời lượng',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppTokens.s8),
                  Row(
                      children: LeaveDuration.values
                          .map((d) => Expanded(
                              child: GestureDetector(
                                  onTap: () => setState(() {
                                        _duration = d;
                                        if (d != LeaveDuration.fullDay) {
                                          _toDate = _fromDate;
                                        }
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
                                      borderRadius: BorderRadius.circular(AppTokens.rMicro),
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
                  const SizedBox(height: AppTokens.s12),
                ] else ...[
                  if (_selectedType == LeaveType.shiftChange) ...[
                    // Chế độ đổi ca
                    Text('Chế độ đổi ca',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _shiftChangeMode = 'TIME';
                              _shiftChangeDate = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _shiftChangeMode == 'TIME'
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rMicro),
                                border: Border.all(
                                  color: _shiftChangeMode == 'TIME'
                                      ? AppColors.primaryBlue
                                      : (widget.isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                ),
                              ),
                              child: Text(
                                'Đổi giờ (Cùng ngày)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _shiftChangeMode == 'TIME'
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _shiftChangeMode = 'DATE';
                              _shiftChangeDate ??= _fromDate;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _shiftChangeMode == 'DATE'
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rMicro),
                                border: Border.all(
                                  color: _shiftChangeMode == 'DATE'
                                      ? AppColors.primaryBlue
                                      : (widget.isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                ),
                              ),
                              child: Text(
                                'Đổi ngày làm bù',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _shiftChangeMode == 'DATE'
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_shiftChangeMode == 'DATE') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              'Ngày nghỉ (Ca cũ)',
                              _shiftChangeDate ?? _fromDate,
                              (d) => setState(() => _shiftChangeDate = d),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s12),
                          Expanded(
                            child: _DateField(
                              'Ngày làm bù (Ca mới)',
                              _fromDate,
                              (d) => setState(() => _fromDate = d),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      _DateField(
                        'Ngày áp dụng',
                        _fromDate,
                        (d) => setState(() => _fromDate = d),
                      ),
                    const SizedBox(height: 12),
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
                              labelText: 'Giờ bắt đầu ca mới (HH:mm)',
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
                              labelText: 'Giờ kết thúc ca mới',
                              prefixIcon:
                                  Icon(Icons.access_time_rounded, size: 18),
                            ),
                            onChanged: (v) => _shiftEndTime = v,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _DateField(
                        'Ngày áp dụng',
                        _fromDate,
                        (d) => setState(() => _fromDate = d)),
                    const SizedBox(height: 12),
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
                            ? 'Giờ đến muộn dự kiến (HH:mm)'
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
                  ],
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enableSuggestions: true,
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
                            'Số ngày (trừ CN): ${_calculateWorkingDays(_fromDate, _duration != LeaveDuration.fullDay ? _fromDate : _toDate, _duration)} ngày',
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
            borderRadius: BorderRadius.circular(AppTokens.rInput),
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
