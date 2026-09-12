import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_tokens.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/attendance_correction.dart';

class AttendanceCorrectionCard extends StatelessWidget {
  final AttendanceCorrection item;
  final bool isDark;
  final VoidCallback onCancel;

  const AttendanceCorrectionCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onCancel,
  });

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          onTap: () => _showDetailSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ngày gửi & Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.s4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTokens.rMicro),
                      ),
                      child: const Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                    ),
                    const Spacer(),
                    StatusBadge.requestStatus(item.status.label),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),

                // Thông tin ngày cần sửa
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppTokens.s4),
                    Text(
                      'Ngày chấm công: ${_formatDate(item.date)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),

                // TimeIn / TimeOut badges
                Row(
                  children: [
                    _TimeBadge(
                      label: 'Vào (In)',
                      time: item.timeIn ?? '--:--',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppTokens.s8),
                    _TimeBadge(
                      label: 'Ra (Out)',
                      time: item.timeOut ?? '--:--',
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),

                // Lý do
                Text(
                  'Lý do: ${item.reason}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                ),

                // Nút huỷ nếu đang PENDING
                if (item.status == AttendanceCorrectionStatus.pending) ...[
                  const SizedBox(height: AppTokens.s8),
                  const Divider(height: 1),
                  const SizedBox(height: AppTokens.s4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                          vertical: AppTokens.s4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Huỷ đơn', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.rCard),
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.s24),
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
            const SizedBox(height: AppTokens.s16),
            Text(
              'Chi tiết Yêu cầu Chấm công lại',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.s12),
            StatusBadge.requestStatus(item.status.label),
            const SizedBox(height: AppTokens.s16),
            _DetailRow('Ngày gửi:', DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt)),
            _DetailRow('Ngày chấm công:', _formatDate(item.date)),
            _DetailRow('Giờ vào (In):', item.timeIn ?? 'Không sửa'),
            _DetailRow('Giờ ra (Out):', item.timeOut ?? 'Không sửa'),
            _DetailRow('Lý do:', item.reason),
            if (item.approverName != null && item.approverName!.isNotEmpty)
              _DetailRow('Người duyệt:', item.approverName!),
            if (item.approvedAt != null)
              _DetailRow('Thời gian duyệt:', DateFormat('dd/MM/yyyy HH:mm').format(item.approvedAt!)),
            const SizedBox(height: AppTokens.s24),
            if (item.status == AttendanceCorrectionStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel();
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Huỷ yêu cầu này'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.rInput),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimeBadge({
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: AppTokens.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.rMicro),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: color),
          const SizedBox(width: AppTokens.s4),
          Text(
            '$label: $time',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
