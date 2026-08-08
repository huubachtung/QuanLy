import 'package:flutter/material.dart';
import 'package:app/core/utils/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  factory StatusBadge.projectStatus(String status) {
    Color color;
    switch (status) {
      case 'Chưa bắt đầu': color = AppColors.statusNotStarted; break;
      case 'Đang thực hiện': color = AppColors.statusInProgress; break;
      case 'Hoàn thành': color = AppColors.statusFinished; break;
      case 'Trễ hạn': color = AppColors.statusDelayed; break;
      default: color = AppColors.statusNotStarted;
    }
    return StatusBadge(label: status, color: color);
  }

  factory StatusBadge.taskStatus(String status) {
    Color color;
    switch (status) {
      case 'Đang làm': color = AppColors.statusInProgress; break;
      case 'Hoàn thành': color = AppColors.statusFinished; break;
      case 'Chưa làm': color = AppColors.statusNotStarted; break;
      case 'Đã huỷ': color = AppColors.statusCancelled; break;
      default: color = AppColors.statusNotStarted;
    }
    return StatusBadge(label: status, color: color);
  }

  factory StatusBadge.requestStatus(String status) {
    Color color;
    switch (status) {
      case 'Chờ duyệt': color = AppColors.warning; break;
      case 'Đã duyệt': color = AppColors.success; break;
      case 'Từ chối': color = AppColors.error; break;
      case 'Đã huỷ': color = AppColors.statusCancelled; break;
      default: color = AppColors.statusNotStarted;
    }
    return StatusBadge(label: status, color: color);
  }

  factory StatusBadge.otStatus(String status) {
    Color color;
    switch (status) {
      case 'Đã duyệt': color = AppColors.success; break;
      case 'Chờ duyệt': color = AppColors.warning; break;
      case 'Từ chối': color = AppColors.error; break;
      default: color = AppColors.statusNotStarted;
    }
    return StatusBadge(label: status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor ?? color,
        ),
      ),
    );
  }
}

class AttendanceStatusBadge extends StatelessWidget {
  final String status;
  const AttendanceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Hoàn thành': color = AppColors.attendanceDone; break;
      case 'Đi muộn': color = AppColors.attendanceLate; break;
      case 'Về sớm': color = AppColors.attendanceEarlyLeave; break;
      case 'Đi muộn & Về sớm': color = AppColors.attendanceLateEarly; break;
      case 'Vắng mặt': color = AppColors.attendanceAbsent; break;
      case 'Chưa chấm công về': color = AppColors.attendancePending; break;
      case 'Nghỉ phép': color = AppColors.info; break;
      default: color = Colors.grey;
    }
    return StatusBadge(label: status, color: color, fontSize: 10,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3));
  }
}
