import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/overtime_model.dart';
import '../bloc/overtime/overtime_bloc.dart';
import '../bloc/overtime/overtime_event.dart';
import '../bloc/overtime/overtime_state.dart';
import '../../../../shared/widgets/month_picker.dart';
import '../../../../shared/widgets/empty_state.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});
  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  final Map<String, TextEditingController> _hoursCtrl = {};
  final Map<String, TextEditingController> _reasonCtrl = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context
          .read<OvertimeBloc>()
          .add(LoadOvertimeData(month: now.month, year: now.year));
    });
  }

  @override
  void dispose() {
    for (final c in _hoursCtrl.values) {
      c.dispose();
    }
    for (final c in _reasonCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getHoursCtrl(OvertimeModel r) {
    return _hoursCtrl.putIfAbsent(
        r.date,
        () => TextEditingController(
            text: r.requestedOtHours > 0
                ? (r.requestedOtHours % 1 == 0
                    ? r.requestedOtHours.toInt().toString()
                    : r.requestedOtHours.toString())
                : (r.calculatedOtHours > 0
                    ? (r.calculatedOtHours % 1 == 0
                        ? r.calculatedOtHours.toInt().toString()
                        : r.calculatedOtHours.toString())
                    : '0')));
  }

  TextEditingController _getReasonCtrl(OvertimeModel r) {
    return _reasonCtrl.putIfAbsent(
        r.date, () => TextEditingController(text: r.reason));
  }

  void _saveSingle(OvertimeModel r) {
    final hoursText = _hoursCtrl[r.date]?.text.trim() ?? '0';
    final hours = double.tryParse(hoursText) ?? 0.0;
    final reason = _reasonCtrl[r.date]?.text.trim() ?? '';

    if (hours < 0 || hours > 8) {
      setState(() => _errors[r.date] = 'Số giờ OT từ 0 đến 8 giờ');
      return;
    }

    if (hours > 0 && reason.isEmpty) {
      setState(() => _errors[r.date] = 'Vui lòng nhập lý do tăng ca');
      return;
    }

    setState(() => _errors.remove(r.date));
    context.read<OvertimeBloc>().add(
        UpdateOvertimeRecord(date: r.date, requestedHours: hours, reason: reason));
  }

  void _confirmDelete(OvertimeModel r) {
    if (r.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa yêu cầu OT', style: TextStyle(fontSize: 16)),
        content: Text('Bạn có chắc muốn xóa yêu cầu OT ngày ${r.date} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OvertimeBloc>().add(DeleteOvertimeRecord(r.id!));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBulk(OvertimeLoaded state) async {
    final entries = <Map<String, dynamic>>[];
    String? invalidDate;

    for (final r in state.records) {
      if (!r.isEditable) continue;

      final hours = double.tryParse(_hoursCtrl[r.date]?.text.trim() ?? '${r.requestedOtHours}') ?? r.requestedOtHours;
      final reason = _reasonCtrl[r.date]?.text.trim() ?? r.reason;

      if (hours > 0) {
        if (reason.isEmpty) {
          invalidDate = r.date;
          setState(() => _errors[r.date] = 'Vui lòng nhập lý do tăng ca');
          break;
        }
        entries.add({
          'date': r.date,
          'hours': hours,
          'reason': reason,
        });
      }
    }

    if (invalidDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vui lòng nhập đầy đủ lý do cho ngày $invalidDate'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không có ngày tăng ca nào (giờ > 0) để gửi duyệt'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    final totalHours = entries.fold<double>(0.0, (s, e) => s + (e['hours'] as num).toDouble());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gửi duyệt bảng OT tháng ${state.selectedMonth}/${state.selectedYear}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
            'Bạn đang gửi duyệt ${entries.length} ngày tăng ca với tổng cộng ${totalHours.toStringAsFixed(1)} giờ OT.\n\nXác nhận gửi cho Quản lý phê duyệt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Xem lại'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Xác nhận gửi'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<OvertimeBloc>().add(SubmitBulkOvertime(entries));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state is OvertimeActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ));
        } else if (state is OvertimeError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      builder: (context, state) {
        final currentMonth = context.read<OvertimeBloc>().currentMonth;
        final currentYear = context.read<OvertimeBloc>().currentYear;

        return Column(children: [
          // Header Bar with MonthPicker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              MonthYearPicker(
                month: currentMonth,
                year: currentYear,
                onChanged: (mv) {
                  _hoursCtrl.clear();
                  _reasonCtrl.clear();
                  _errors.clear();
                  context
                      .read<OvertimeBloc>()
                      .add(LoadOvertimeData(month: mv.$1, year: mv.$2));
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.timer_rounded,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Tháng $currentMonth/$currentYear',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // Summary stats header
          if (state is OvertimeLoaded && state.records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(
                      label: 'Máy tính',
                      value: '${state.totalCalculatedHours.toStringAsFixed(1)}h',
                      color: AppColors.primaryBlue,
                    ),
                    Container(height: 24, width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _SummaryStat(
                      label: 'Đề xuất',
                      value: '${state.totalRequestedHours.toStringAsFixed(1)}h',
                      color: AppColors.warning,
                    ),
                    Container(height: 24, width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _SummaryStat(
                      label: 'Đã duyệt',
                      value: '${state.totalApprovedHours.toStringAsFixed(1)}h',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

          if (state is OvertimeLoading || state is OvertimeInitial)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state is OvertimeLoaded && state.records.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.timer_off_rounded,
                title: 'Không có dữ liệu chấm công OT trong tháng này',
              ),
            )
          else if (state is OvertimeLoaded) ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                itemCount: state.records.length,
                itemBuilder: (_, i) {
                  final r = state.records[i];
                  return _OtCard(
                    record: r,
                    isDark: isDark,
                    hoursCtrl: _getHoursCtrl(r),
                    reasonCtrl: _getReasonCtrl(r),
                    error: _errors[r.date],
                    onSave: () => _saveSingle(r),
                    onNoOt: () {
                      _hoursCtrl[r.date]?.text = '0';
                      _reasonCtrl[r.date]?.text = 'Không OT';
                      context.read<OvertimeBloc>().add(MarkNoOt(r.date));
                    },
                    onDelete: () => _confirmDelete(r),
                  );
                },
              ),
            ),

            // Floating Bottom Bar for Bulk Submission
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                    top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isSubmitting ? null : () => _submitBulk(state),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      state.isSubmitting
                          ? 'Đang gửi duyệt...'
                          : 'Gửi duyệt toàn bộ bảng OT tháng',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ]
        ]);
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _OtCard extends StatelessWidget {
  final OvertimeModel record;
  final bool isDark;
  final TextEditingController hoursCtrl;
  final TextEditingController reasonCtrl;
  final String? error;
  final VoidCallback onSave;
  final VoidCallback onNoOt;
  final VoidCallback onDelete;

  const _OtCard({
    required this.record,
    required this.isDark,
    required this.hoursCtrl,
    required this.reasonCtrl,
    this.error,
    required this.onSave,
    required this.onNoOt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(record.date) ?? DateTime.now();
    final dayOfWeek = record.dayOfWeek > 0 ? record.dayOfWeek : (date.weekday == 7 ? 0 : date.weekday);
    final isWeekend = dayOfWeek == 0 || dayOfWeek == 6; // CN hoặc T7
    final weekdayNames = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    final weekdayStr = dayOfWeek >= 0 && dayOfWeek < 7 ? weekdayNames[dayOfWeek] : 'Thứ ${dayOfWeek + 1}';

    final isApproved = record.status == OtStatus.approved;
    final isRejected = record.status == OtStatus.rejected;
    final isPending = record.status == OtStatus.pending;

    final checkIn = record.checkIn != null && record.checkIn!.isNotEmpty ? record.checkIn! : '--:--';
    final checkOut = record.checkOut != null && record.checkOut!.isNotEmpty ? record.checkOut! : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isApproved
              ? AppColors.success.withValues(alpha: 0.5)
              : (isRejected
                  ? AppColors.error.withValues(alpha: 0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: isApproved ? 1.5 : 1.0,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card Top Header
        Row(children: [
          // Date Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isWeekend
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ($weekdayStr)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isWeekend
                    ? AppColors.warning
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Checkin - Checkout
          Expanded(
            child: Text(
              '$checkIn → $checkOut',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status Chip
          _StatusChip(record.status),
        ]),

        const SizedBox(height: 8),

        // Calculated OT Row
        Row(
          children: [
            Icon(Icons.precision_manufacturing_rounded,
                size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 4),
            Text(
              'Hệ thống ghi nhận: ',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              '${record.calculatedOtHours.toStringAsFixed(1)}h',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (isApproved && record.approverName.isNotEmpty)
              Text(
                'Duyệt bởi: ${record.approverName}',
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
          ],
        ),

        // Rejection banner if rejected
        if (isRejected && record.rejectReason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lý do từ chối: ${record.rejectReason}',
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
            ]),
          ),
        ],

        // Input Fields (if editable)
        if (record.isEditable) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Hours Stepper / Input
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: hoursCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Giờ xin (h)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Reason Input
            Expanded(
              child: TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Lý do tăng ca *',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  errorText: error,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Actions
          Row(children: [
            // Không OT button
            Expanded(
              child: OutlinedButton(
                onPressed: onNoOt,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Không OT', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            // Lưu ngày này button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded, size: 14),
                label: const Text('Lưu', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            // Delete button (if pending)
            if (isPending && record.id != null) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                tooltip: 'Xóa đơn OT',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ]),
        ],
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OtStatus status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext ctx) {
    Color color;
    switch (status) {
      case OtStatus.approved:
        color = AppColors.success;
        break;
      case OtStatus.pending:
        color = AppColors.primaryBlue;
        break;
      case OtStatus.pendingConfirmation:
        color = AppColors.warning;
        break;
      case OtStatus.rejected:
        color = AppColors.error;
        break;
      case OtStatus.none:
        color = AppColors.statusNotStarted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
