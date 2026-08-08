import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/overtime_model.dart';
import '../bloc/overtime/overtime_bloc.dart';
import '../bloc/overtime/overtime_event.dart';
import '../bloc/overtime/overtime_state.dart';
import '../../../../shared/widgets/month_picker.dart';
import '../../../../shared/widgets/empty_state.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});
  @override State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  final Map<String, TextEditingController> _hoursCtrl = {};
  final Map<String, TextEditingController> _reasonCtrl = {};
  final Map<String, String?> _errors = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<OvertimeBloc>().add(LoadOvertimeData(month: now.month, year: now.year));
    });
  }

  @override void dispose() {
    for (final c in _hoursCtrl.values) c.dispose();
    for (final c in _reasonCtrl.values) c.dispose();
    super.dispose();
  }

  TextEditingController _getHoursCtrl(OvertimeModel r) {
    return _hoursCtrl.putIfAbsent(r.id, () => TextEditingController(text: r.requestedHours.toString()));
  }
  TextEditingController _getReasonCtrl(OvertimeModel r) {
    return _reasonCtrl.putIfAbsent(r.id, () => TextEditingController(text: r.reason));
  }

  void _save(OvertimeModel r) {
    final hours = double.tryParse(_hoursCtrl[r.id]?.text ?? '0') ?? 0;
    final reason = _reasonCtrl[r.id]?.text.trim() ?? '';
    if (hours > 0 && reason.isEmpty) {
      setState(() => _errors[r.id] = 'Vui lòng nhập lý do tăng ca chi tiết');
      return;
    }
    setState(() => _errors.remove(r.id));
    context.read<OvertimeBloc>().add(UpdateOvertimeRecord(id: r.id, requestedHours: hours, reason: reason));
  }

  Future<void> _submitAll(OvertimeLoaded state) async {
    final pending = state.pendingRecords;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không có bản ghi OT mới cần gửi phê duyệt'),
        backgroundColor: AppColors.warning));
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Đã gửi ${pending.length} bản ghi OT chờ duyệt'),
        backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocConsumer<OvertimeBloc, OvertimeState>(
      listener: (context, state) {
        if (state is OvertimeActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message), duration: const Duration(seconds: 1),
            backgroundColor: AppColors.success));
        } else if (state is OvertimeError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message), backgroundColor: AppColors.error));
        }
      },
      builder: (context, state) {
        final currentMonth = context.read<OvertimeBloc>().currentMonth;
        final currentYear = context.read<OvertimeBloc>().currentYear;

        return Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              MonthYearPicker(
                month: currentMonth, year: currentYear,
                onChanged: (mv) {
                  _hoursCtrl.clear(); _reasonCtrl.clear(); _errors.clear();
                  context.read<OvertimeBloc>().add(LoadOvertimeData(month: mv.$1, year: mv.$2));
                },
              ),
              const Spacer(),
              if (state is OvertimeLoaded)
                Text('Tổng: ${state.totalRequestedHours.toStringAsFixed(1)}h',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
            ]),
          ),
          if (state is OvertimeLoading || state is OvertimeInitial)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state is OvertimeLoaded && state.records.isEmpty)
            const Expanded(child: EmptyState(icon: Icons.timer_off_rounded, title: 'Không có dữ liệu OT trong tháng này'))
          else if (state is OvertimeLoaded) ...[
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: state.records.length,
              itemBuilder: (_, i) {
                final r = state.records[i];
                return _OtCard(
                  record: r, isDark: isDark,
                  hoursCtrl: _getHoursCtrl(r),
                  reasonCtrl: _getReasonCtrl(r),
                  error: _errors[r.id],
                  onSave: () => _save(r),
                  onNoOt: () => context.read<OvertimeBloc>().add(MarkNoOt(r.id)),
                );
              },
            )),
            // Submit button
            if (state.records.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: SafeArea(child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _submitAll(state),
                  icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Xác nhận gửi bảng công OT'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ))),
              ),
          ]
        ]);
      },
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

  const _OtCard({
    required this.record, required this.isDark, required this.hoursCtrl,
    required this.reasonCtrl, this.error, required this.onSave, required this.onNoOt,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record.date);
    final weekdays = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    final isApproved = record.status == OtRequestStatus.approved;
    final checkIn = record.checkIn != null ? DateFormat('HH:mm').format(record.checkIn!) : '--';
    final checkOut = record.checkOut != null ? DateFormat('HH:mm').format(record.checkOut!) : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isApproved
          ? AppColors.success.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')} - ${weekdays[date.weekday]}',
              style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$checkIn → $checkOut',
              style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Hệ thống: ${record.systemOtHours.toStringAsFixed(1)}h',
              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 4),
            _StatusChip(record.status),
          ]),
        ]),
        if (!isApproved) ...[
          const SizedBox(height: 12),
          Row(children: [
            // Hours input
            SizedBox(width: 90, child: TextField(
              controller: hoursCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'OT đề nghị (h)',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            )),
            const SizedBox(width: 10),
            // Reason input
            Expanded(child: TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                labelText: 'Lý do tăng ca *',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                errorText: error,
              ),
            )),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: onNoOt,
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Không OT', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Lưu', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OtRequestStatus status;
  const _StatusChip(this.status);
  @override Widget build(BuildContext ctx) {
    Color color;
    switch (status) {
      case OtRequestStatus.approved: color = AppColors.success; break;
      case OtRequestStatus.pending: color = AppColors.warning; break;
      case OtRequestStatus.rejected: color = AppColors.error; break;
      default: color = AppColors.statusNotStarted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)));
  }
}
