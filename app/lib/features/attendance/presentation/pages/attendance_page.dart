import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/attendance_model.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../../../shared/widgets/month_picker.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final isLoading = state is AttendanceInitial || state is AttendanceLoading;
        final currentMonth = context.read<AttendanceBloc>().currentMonth;
        final currentYear = context.read<AttendanceBloc>().currentYear;

        AttendanceSummary? summary;
        List<AttendanceModel> records = [];

        if (state is AttendanceLoaded) {
          summary = state.summary;
          records = state.records;
        }

        return Column(children: [
          // Month picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              MonthYearPicker(
                month: currentMonth, year: currentYear,
                onChanged: (mv) {
                  context.read<AttendanceBloc>().add(LoadAttendanceData(month: mv.$1, year: mv.$2));
                },
              ),
              const Spacer(),
              Icon(Icons.fingerprint_rounded, color: Theme.of(context).colorScheme.primary),
            ]),
          ),
          if (isLoading || summary == null)
            Expanded(child: ListView.builder(itemCount: 8, itemBuilder: (_, __) => const CardShimmer()))
          else ...[
            // Summary card
            _SummaryCard(summary: summary, isDark: isDark),
            const SizedBox(height: 8),
            // Header row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                _HdrCell('Ngày', flex: 2), _HdrCell('Vào', flex: 2),
                _HdrCell('Ra', flex: 2), _HdrCell('HC', flex: 1),
                _HdrCell('OT', flex: 1), _HdrCell('Công', flex: 1),
              ]),
            ),
            const SizedBox(height: 4),
            // Records
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: records.length,
              itemBuilder: (_, i) => _AttRow(record: records[i], isDark: isDark),
            )),
          ],
        ]);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AttendanceSummary summary;
  final bool isDark;
  const _SummaryCard({required this.summary, required this.isDark});

  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(children: [
        Row(children: [
          _SumItem('Ngày đi làm', '${summary.workDays}', AppColors.info),
          _SumItem('Tổng công', summary.totalCong.toStringAsFixed(1), AppColors.success),
          _SumItem('Giờ HC', summary.totalNormalHours.toStringAsFixed(1), AppColors.primaryLight),
        ]),
        const Divider(height: 16),
        Row(children: [
          _SumItem('OT duyệt', '${summary.approvedOtHours.toStringAsFixed(1)}h', AppColors.success),
          _SumItem('OT chờ', '${summary.pendingOtHours.toStringAsFixed(1)}h', AppColors.warning),
          _SumItem('OT từ chối', '${summary.rejectedOtHours.toStringAsFixed(1)}h', AppColors.error),
        ]),
      ]),
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumItem(this.label, this.value, this.color);
  @override Widget build(BuildContext ctx) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 10, color: Theme.of(ctx).textTheme.bodySmall?.color), textAlign: TextAlign.center),
  ]));
}

class _HdrCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HdrCell(this.text, {required this.flex});
  @override Widget build(BuildContext ctx) => Expanded(flex: flex,
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700), textAlign: TextAlign.center));
}

class _AttRow extends StatelessWidget {
  final AttendanceModel record;
  final bool isDark;
  const _AttRow({required this.record, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isOff = record.status == AttendanceStatus.off;
    if (isOff) return const SizedBox.shrink();

    final date = DateTime.parse(record.date);
    final weekday = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][date.weekday];
    final checkIn = record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--:--';
    final checkOut = record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--:--';
    final isAbsent = record.status == AttendanceStatus.absent;
    Color rowBg;
    switch (record.status) {
      case AttendanceStatus.absent: rowBg = AppColors.error.withValues(alpha: 0.06); break;
      case AttendanceStatus.late: rowBg = AppColors.warning.withValues(alpha: 0.06); break;
      case AttendanceStatus.lateEarlyLeave: rowBg = AppColors.error.withValues(alpha: 0.04); break;
      case AttendanceStatus.done: rowBg = Colors.transparent; break;
      default: rowBg = Colors.transparent;
    }
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: rowBg == Colors.transparent
            ? (isDark ? AppColors.darkCard : AppColors.lightCard) : rowBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder),
        ),
        child: Row(children: [
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(weekday, style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
          ])),
          Expanded(flex: 2, child: Text(isAbsent ? '--' : checkIn,
            style: TextStyle(fontSize: 12, color: isAbsent ? AppColors.error : null), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(isAbsent ? '--' : checkOut,
            style: TextStyle(fontSize: 12, color: isAbsent ? AppColors.error : null), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(record.normalHours.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(
            record.overtimeHours > 0 ? record.overtimeHours.toStringAsFixed(1) : '-',
            style: TextStyle(fontSize: 11, color: record.overtimeHours > 0 ? AppColors.warning : null),
            textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(record.dailyCong.toStringAsFixed(1),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: record.dailyCong >= 1 ? AppColors.success : record.dailyCong == 0 ? AppColors.error : AppColors.warning),
            textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final checkIn = record.checkIn != null ? DateFormat('HH:mm:ss').format(record.checkIn!) : 'Chưa có';
    final checkOut = record.checkOut != null ? DateFormat('HH:mm:ss').format(record.checkOut!) : 'Chưa có';
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.parse(record.date)),
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          AttendanceStatusBadge(status: record.status.label),
          const SizedBox(height: 16),
          _DetailRow('Giờ vào', checkIn),
          _DetailRow('Giờ ra', checkOut),
          _DetailRow('Giờ HC', '${record.normalHours.toStringAsFixed(1)}h'),
          _DetailRow('Giờ OT', '${record.overtimeHours.toStringAsFixed(1)}h'),
          _DetailRow('Số công', record.dailyCong.toStringAsFixed(1)),
          if (record.overtimeHours > 0)
            _DetailRow('Trạng thái OT', record.otStatus.label),
          if (record.note.isNotEmpty)
            _DetailRow('Ghi chú', record.note),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 100, child: Text('$label:', style: Theme.of(ctx).textTheme.bodySmall)),
      Text(value, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]),
  );
}
