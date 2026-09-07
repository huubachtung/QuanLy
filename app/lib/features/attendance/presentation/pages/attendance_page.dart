import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/attendance_model.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/month_picker.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<AttendanceBloc>();
      if (bloc.state is AttendanceInitial) {
        final now = DateTime.now();
        bloc.add(LoadAttendanceData(month: now.month, year: now.year));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final isLoading =
            state is AttendanceInitial || state is AttendanceLoading;
        final currentMonth = context.read<AttendanceBloc>().currentMonth;
        final currentYear = context.read<AttendanceBloc>().currentYear;

        AttendanceSummary? summary;
        List<AttendanceModel> records = [];

        if (state is AttendanceLoaded) {
          summary = state.summary;
          records = state.records;
        }

        return Column(
          children: [
            // Month Picker Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s16,
                AppTokens.s12,
                AppTokens.s16,
                AppTokens.s8,
              ),
              child: Row(
                children: [
                  MonthYearPicker(
                    month: currentMonth,
                    year: currentYear,
                    onChanged: (mv) {
                      context.read<AttendanceBloc>().add(
                            LoadAttendanceData(month: mv.$1, year: mv.$2),
                          );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s12,
                      vertical: AppTokens.s8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTokens.rInput),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppTokens.s4),
                        Text(
                          'Tháng $currentMonth/$currentYear',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (state is AttendanceError)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.s24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppTokens.s12),
                        Text(state.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppTokens.s16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<AttendanceBloc>().add(
                                  LoadAttendanceData(
                                      month: currentMonth, year: currentYear),
                                );
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (isLoading || summary == null)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  itemCount: 4,
                  itemBuilder: (_, __) => const CardShimmer(),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s16,
                    0,
                    AppTokens.s16,
                    AppTokens.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DỮ LIỆU CHUNG THEO THÁNG (Employee Summary Card)
                      _EmployeeMonthlySummaryCard(
                        user: user,
                        summary: summary,
                        isDark: isDark,
                        isExpanded: _isExpanded,
                        onToggleExpand: () =>
                            setState(() => _isExpanded = !_isExpanded),
                      ),

                      const SizedBox(height: AppTokens.s16),

                      // 2. BẢNG CHI TIẾT LỊCH SỬ CHẤM CÔNG THEO NGÀY
                      if (_isExpanded) ...[
                        _DetailedAttendanceSection(
                          records: records,
                          currentMonth: currentMonth,
                          currentYear: currentYear,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ── Card Thống Kê Tổng Quan Theo Tháng Của Nhân Viên ──────────────────────────
class _EmployeeMonthlySummaryCard extends StatelessWidget {
  final dynamic user;
  final AttendanceSummary summary;
  final bool isDark;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _EmployeeMonthlySummaryCard({
    required this.user,
    required this.summary,
    required this.isDark,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.displayName ?? 'Nhân viên';
    final String email = user?.email ?? user?.username ?? '';
    final String employeeCode = user?.employeeCode?.isNotEmpty == true
        ? user!.employeeCode!
        : '---';

    // Tạo avatar ký tự viết tắt
    final initials = displayName
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Header info: Nhân viên, Mã NV, Phòng ban, nút Mở rộng
          Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    initials.isNotEmpty ? initials : 'NV',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tên & Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.department != null && user!.department!.isNotEmpty
                            ? '${user!.department!} • $email'
                            : email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Mã NV Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardElevated
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MÃ NV',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        employeeCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Nút thu gọn / mở rộng chi tiết
                InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Hàng chỉ số tóm tắt: Phòng ban, Số ngày đi làm, Tổng giờ HC, OT duyệt, OT chờ, Tổng công
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _SummaryMetricItem(
                  label: 'SỐ NGÀY ĐI LÀM',
                  valueWidget: Text(
                    '${summary.workDays} ngày',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SummaryMetricItem(
                  label: 'TỔNG GIỜ HC',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.totalNormalHours.toStringAsFixed(summary.totalNormalHours % 1 == 0 ? 0 : 2)} h',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                _SummaryMetricItem(
                  label: 'GIỜ OT ĐÃ DUYỆT',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.approvedOtHours.toStringAsFixed(summary.approvedOtHours % 1 == 0 ? 0 : 1)} h',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                _SummaryMetricItem(
                  label: 'GIỜ OT CHỜ DUYỆT',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${summary.pendingOtHours.toStringAsFixed(summary.pendingOtHours % 1 == 0 ? 0 : 1)} h',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                _SummaryMetricItem(
                  label: 'TỔNG SỐ CÔNG',
                  valueWidget: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${summary.totalCong.toStringAsFixed(summary.totalCong % 1 == 0 ? 0 : 1)} công',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricItem extends StatelessWidget {
  final String label;
  final Widget valueWidget;

  const _SummaryMetricItem({required this.label, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        valueWidget,
      ],
    );
  }
}

/// ── Phần Bảng Chi Tiết Từng Ngày Trong Tháng ─────────────────────────────────
class _DetailedAttendanceSection extends StatelessWidget {
  final List<AttendanceModel> records;
  final int currentMonth;
  final int currentYear;
  final bool isDark;

  const _DetailedAttendanceSection({
    required this.records,
    required this.currentMonth,
    required this.currentYear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 40, color: Theme.of(context).disabledColor),
            const SizedBox(height: 8),
            Text(
              'Chưa có lịch sử chấm công tháng $currentMonth/$currentYear',
              style: TextStyle(
                  color: Theme.of(context).disabledColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tiêu Đề Bảng
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              AppTokens.s16,
              AppTokens.s16,
              AppTokens.s12,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppTokens.s8),
                Text(
                  'Lịch sử quét vân tay (Tháng $currentMonth/$currentYear)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${records.length} ngày',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bảng dữ liệu có thể cuộn ngang mượt mà
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(
                isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
              ),
              headingRowHeight: 40,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 48,
              horizontalMargin: 16,
              columnSpacing: 20,
              columns: const [
                DataColumn(
                    label: Text('Ngày',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Giờ vào',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Giờ ra',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Giờ HC',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Giờ OT',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('★ Công',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primaryBlue))),
                DataColumn(
                    label: Text('Trạng thái',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Trạng thái OT',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
                DataColumn(
                    label: Text('Ghi chú',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12))),
              ],
              rows: records
                  .map((record) => _buildDataRow(context, record, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
      BuildContext context, AttendanceModel record, bool isDark) {
    final date = DateTime.tryParse(record.date) ?? DateTime.now();
    final dateFormatted = DateFormat('dd/MM/yyyy').format(date);
    final checkIn = record.checkIn != null
        ? DateFormat('HH:mm').format(record.checkIn!)
        : '--:--';
    final checkOut = record.checkOut != null
        ? DateFormat('HH:mm').format(record.checkOut!)
        : '--:--';

    // Màu sắc check-in
    final checkInColor = record.status == AttendanceStatus.late ||
            record.status == AttendanceStatus.lateEarlyLeave
        ? AppColors.warning
        : (record.checkIn != null ? AppColors.success : null);

    // Màu sắc check-out
    final checkOutColor = record.checkOut != null
        ? (record.status == AttendanceStatus.earlyLeave
            ? AppColors.error
            : AppColors.primaryBlue)
        : null;

    return DataRow(
      onSelectChanged: (_) => _showDetailSheet(context, record),
      cells: [
        // 1. Ngày
        DataCell(
          Text(
            dateFormatted,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        // 2. Giờ vào
        DataCell(
          Text(
            checkIn,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: checkInColor,
            ),
          ),
        ),
        // 3. Giờ ra
        DataCell(
          Text(
            checkOut,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: checkOutColor,
            ),
          ),
        ),
        // 4. Giờ HC
        DataCell(
          Text(
            '${record.normalHours.toStringAsFixed(record.normalHours % 1 == 0 ? 0 : 1)}h',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // 5. Giờ OT
        DataCell(
          Text(
            record.overtimeHours > 0
                ? '${record.overtimeHours.toStringAsFixed(1)}h'
                : '0h',
            style: TextStyle(
              fontSize: 12,
              color: record.overtimeHours > 0 ? AppColors.warning : null,
              fontWeight: record.overtimeHours > 0
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
        // 6. Công
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: record.dailyCong >= 1
                  ? AppColors.success.withValues(alpha: 0.15)
                  : (record.dailyCong > 0
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.dailyCong > 0
                  ? record.dailyCong
                      .toStringAsFixed(record.dailyCong % 1 == 0 ? 0 : 1)
                  : '0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: record.dailyCong >= 1
                    ? AppColors.success
                    : (record.dailyCong > 0
                        ? AppColors.warning
                        : Theme.of(context).disabledColor),
              ),
            ),
          ),
        ),
        // 7. Trạng thái
        DataCell(_buildAttendanceStatusBadge(record)),
        // 8. Trạng thái OT
        DataCell(_buildOtStatusBadge(record)),
        // 9. Ghi chú
        DataCell(
          Text(
            record.note.isNotEmpty ? record.note : '-',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusBadge(AttendanceModel record) {
    if (record.isLeave) {
      return const StatusBadge(
          label: 'Nghỉ phép', color: Color(0xFF8B5CF6), fontSize: 11);
    }
    switch (record.status) {
      case AttendanceStatus.done:
        return const StatusBadge(
            label: 'Hoàn thành', color: AppColors.success, fontSize: 11);
      case AttendanceStatus.late:
        return const StatusBadge(
            label: 'Đi muộn', color: AppColors.warning, fontSize: 11);
      case AttendanceStatus.earlyLeave:
        return const StatusBadge(
            label: 'Về sớm', color: AppColors.error, fontSize: 11);
      case AttendanceStatus.lateEarlyLeave:
        return const StatusBadge(
            label: 'Muộn & Về sớm', color: AppColors.error, fontSize: 11);
      case AttendanceStatus.pending:
        return const StatusBadge(
            label: 'Hiện diện', color: AppColors.primaryBlue, fontSize: 11);
      case AttendanceStatus.absent:
        return const StatusBadge(
            label: 'Vắng mặt', color: AppColors.error, fontSize: 11);
      case AttendanceStatus.leave:
        return const StatusBadge(
            label: 'Nghỉ phép', color: Color(0xFF8B5CF6), fontSize: 11);
      case AttendanceStatus.off:
        return const StatusBadge(
            label: 'Ngày nghỉ', color: Colors.grey, fontSize: 11);
    }
  }

  Widget _buildOtStatusBadge(AttendanceModel record) {
    if (record.overtimeHours <= 0) {
      return const Text('-',
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    switch (record.otStatus) {
      case OtStatus.approved:
        return const StatusBadge(
            label: 'Đã duyệt', color: AppColors.success, fontSize: 11);
      case OtStatus.pending:
        return const StatusBadge(
            label: 'Chờ duyệt', color: AppColors.warning, fontSize: 11);
      case OtStatus.rejected:
        return const StatusBadge(
            label: 'Từ chối', color: AppColors.error, fontSize: 11);
      case OtStatus.none:
        return const Text('-',
            style: TextStyle(color: Colors.grey, fontSize: 12));
    }
  }

  void _showDetailSheet(BuildContext context, AttendanceModel record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkIn = record.checkIn != null
        ? DateFormat('HH:mm:ss').format(record.checkIn!)
        : 'Chưa có';
    final checkOut = record.checkOut != null
        ? DateFormat('HH:mm:ss').format(record.checkOut!)
        : 'Chưa có';
    final date = DateTime.tryParse(record.date) ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(AppTokens.s24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.rCard),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildAttendanceStatusBadge(record),
                const SizedBox(width: 8),
                if (record.overtimeHours > 0) _buildOtStatusBadge(record),
              ],
            ),
            const SizedBox(height: 16),
            _DetailModalRow(label: 'Giờ vào', value: checkIn),
            _DetailModalRow(label: 'Giờ ra', value: checkOut),
            _DetailModalRow(
                label: 'Giờ hành chính',
                value: '${record.normalHours.toStringAsFixed(1)}h'),
            _DetailModalRow(
                label: 'Giờ tăng ca (OT)',
                value: '${record.overtimeHours.toStringAsFixed(1)}h'),
            _DetailModalRow(
                label: 'Số công',
                value: '${record.dailyCong.toStringAsFixed(1)} công'),
            if (record.overtimeHours > 0)
              _DetailModalRow(
                  label: 'Trạng thái OT', value: record.otStatus.label),
            if (record.note.isNotEmpty)
              _DetailModalRow(label: 'Ghi chú', value: record.note),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailModalRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailModalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
