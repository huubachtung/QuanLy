import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';

class MonthYearPicker extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<(int month, int year)> onChanged;

  const MonthYearPicker({
    super.key,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final label = DateFormat('MM/yyyy').format(DateTime(year, month));
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.rInput),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: () {
            var m = month - 1; var y = year;
            if (m < 1) { m = 12; y--; }
            onChanged((m, y));
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
            child: Text('Tháng $label',
              style: Theme.of(context).textTheme.titleSmall),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: () {
            var m = month + 1; var y = year;
            if (m > 12) { m = 1; y++; }
            if (DateTime(y, m).isAfter(DateTime.now())) return;
            onChanged((m, y));
          }),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.rMicro),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s8),
        child: Icon(icon, size: AppTokens.iconAction, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}
