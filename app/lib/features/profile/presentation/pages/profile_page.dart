import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/user_model.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_event.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user as UserModel; // We know it's a UserModel because of Data/Domain
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final fmt = DateFormat('dd/MM/yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar & name card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.primaryLight : AppColors.primaryBlue,
                      isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1E4A9A)
                    ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.primaryLight : AppColors.primaryBlue).withValues(alpha: 0.3),
                      blurRadius: 12, offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Row(children: [
                  Hero(
                    tag: 'user_avatar',
                    child: CircleAvatar(
                      radius: 32, backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(user.displayName.substring(0, 1),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.displayName, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(user.employeeCode ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(user.department ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)),
                      child: Text(_roleLabel(user.role),
                        style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ])),
                ]),
              ),
              const SizedBox(height: 16),
              // Quick stats
              Row(children: [
                _QuickStat('Phép còn lại', '${user.leaveBalances.firstWhere((lb) => lb.leaveType == "ANNUAL_LEAVE", orElse: () => const LeaveBalance(leaveType: '', label: '', totalDays: 12, usedDays: 0)).remainingDays.toStringAsFixed(1)} ngày', AppColors.success, isDark),
                const SizedBox(width: 8),
                _QuickStat('Ngày vào làm', user.hiredDate != null ? fmt.format(user.hiredDate!) : 'N/A', AppColors.info, isDark),
                const SizedBox(width: 8),
                _QuickStat('Loại HĐ', _employeeTypeLabel(user.employeeType), AppColors.purple, isDark),
              ]),
              const SizedBox(height: 16),
              // Personal info
              _InfoSection('Thông tin liên hệ', [
                _InfoRow(Icons.email_outlined, 'Email', user.email, context),
                _InfoRow(Icons.phone_outlined, 'Điện thoại', user.phone ?? 'N/A', context),
              ], isDark, context),
              const SizedBox(height: 12),
              _InfoSection('Thông tin công việc', [
                _InfoRow(Icons.work_outline_rounded, 'Chức vụ', _roleLabel(user.role), context),
                _InfoRow(Icons.business_rounded, 'Phòng ban', user.department ?? 'N/A', context),
                _InfoRow(Icons.access_time_rounded, 'Giờ làm việc',
                  '${user.workStartTime} - ${user.workEndTime}', context),
              ], isDark, context),
              const SizedBox(height: 24),
              // Logout
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )),
              const SizedBox(height: 24),
            ]),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Quản trị viên';
      case 'leader': return 'Trưởng nhóm';
      case 'accountant': return 'Kế toán';
      default: return 'Nhân viên';
    }
  }

  String _employeeTypeLabel(String type) {
    switch (type) {
      case 'FULL_TIME': return 'Toàn thời gian';
      case 'PART_TIME': return 'Bán thời gian';
      case 'INTERN': return 'Thực tập';
      case 'COLLABORATOR': return 'Cộng tác viên';
      default: return type;
    }
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _QuickStat(this.label, this.value, this.color, this.isDark);
  @override Widget build(BuildContext ctx) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 9, color: Theme.of(ctx).textTheme.bodySmall?.color), textAlign: TextAlign.center),
    ]),
  ));
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final bool isDark;
  final BuildContext ctx;
  const _InfoSection(this.title, this.rows, this.isDark, this.ctx);

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(ctx).textTheme.titleSmall),
      const SizedBox(height: 12),
      ...rows,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final BuildContext ctx;
  const _InfoRow(this.icon, this.label, this.value, this.ctx);
  @override Widget build(BuildContext _) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: Theme.of(ctx).colorScheme.primary),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(ctx).textTheme.labelSmall),
        Text(value, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}
