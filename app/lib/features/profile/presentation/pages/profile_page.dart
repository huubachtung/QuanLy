import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import 'package:app/core/widgets/app_avatar.dart';
import 'package:app/features/auth/domain/entities/user_entity.dart';
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
          final user = state.user;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final fmt = DateFormat('dd/MM/yyyy');

          final displayName = user.displayName.trim();
          final effectiveName = displayName.isNotEmpty ? displayName : (user.username.isNotEmpty ? user.username : 'Chưa đặt tên');
          final leaveBal = (user.annualLeaveBalance as num?)?.toDouble() ?? 12.0;
          final leaveStr = '${leaveBal % 1 == 0 ? leaveBal.toInt() : leaveBal} ngày';
          final hiredDateStr = user.hiredDate != null ? fmt.format(user.hiredDate!) : 'N/A';
          final empTypeStr = _employeeTypeLabel(user.employeeType);
          final positionStr = (user.position != null && user.position!.trim().isNotEmpty)
              ? user.position!.trim()
              : _roleLabel(user.role);

          final deptDisplay = (user.department != null && user.department!.trim().isNotEmpty)
              ? user.department!.trim()
              : ((user.departmentId != null && user.departmentId!.trim().isNotEmpty)
                  ? user.departmentId!.trim()
                  : null);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(UserProfileRefreshRequested());
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Avatar & name card
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isDark ? AppColors.primaryLight : AppColors.primaryBlue,
                        isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1E4A9A)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppColors.primaryBlue).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    AppAvatar(
                      avatarUrl: user.avatar,
                      name: effectiveName,
                      radius: 32,
                      fontSize: 22,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        effectiveName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      if (user.employeeCode != null && user.employeeCode!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          'Mã NV: ${user.employeeCode!.trim()}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (deptDisplay != null) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text(deptDisplay, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                      const SizedBox(height: AppTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppTokens.rMicro),
                        ),
                        child: Text(
                          positionStr,
                          style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ])),
                  ]),
                ),
                const SizedBox(height: AppTokens.s16),
                // Quick stats
                Row(children: [
                  Expanded(
                    child: _QuickStat('Phép còn lại', leaveStr, AppColors.success, isDark),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _QuickStat('Ngày vào làm', hiredDateStr, AppColors.info, isDark),
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Expanded(
                    child: _QuickStat('Loại HĐ', empTypeStr, AppColors.purple, isDark),
                  ),
                ]),
                const SizedBox(height: AppTokens.s16),
                // Personal info
                _InfoSection('Thông tin liên hệ', [
                  _InfoRow(Icons.email_outlined, 'Email', user.email, context),
                  _InfoRow(Icons.phone_outlined, 'Điện thoại', user.phone?.isNotEmpty == true ? user.phone! : 'N/A', context),
                ], isDark, context),
                const SizedBox(height: AppTokens.s12),
                // Work info
                _InfoSection('Thông tin công việc', [
                  _InfoRow(
                    Icons.badge_outlined,
                    'Mã nhân viên',
                    user.employeeCode?.isNotEmpty == true ? user.employeeCode! : 'N/A',
                    context,
                  ),
                  _InfoRow(
                    Icons.business_outlined,
                    'Phòng ban',
                    deptDisplay?.isNotEmpty == true ? deptDisplay! : 'N/A',
                    context,
                  ),
                  _InfoRow(
                    Icons.work_outline_rounded,
                    'Chức vụ',
                    positionStr,
                    context,
                  ),
                  _InfoRow(
                    Icons.access_time_rounded,
                    'Giờ làm việc',
                    '${user.workStartTime ?? "08:30"} - ${user.workEndTime ?? "17:30"}',
                    context,
                  ),
                ], isDark, context),

                // Chi tiết các loại phép (nếu có trong dữ liệu tài khoản từ backend)
                if (user.leaveBalances.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s12),
                  _LeaveBalancesSection(
                    leaveBalances: user.leaveBalances,
                    isDark: isDark,
                    ctx: context,
                  ),
                ],

                const SizedBox(height: AppTokens.s24),
                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.rInput),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
              ]),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _roleLabel(dynamic role) {
    if (role == null) return 'Nhân viên';
    final str = role.toString().trim();
    switch (str.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'leader':
        return 'Trưởng nhóm';
      case 'accountant':
        return 'Kế toán';
      default:
        return 'Nhân viên';
    }
  }

  String _employeeTypeLabel(dynamic type) {
    if (type == null) return 'Chính thức';
    final str = type.toString().trim();
    if (str.isEmpty) return 'Chính thức';
    switch (str.toUpperCase()) {
      case 'FULL_TIME':
        return 'Toàn thời gian';
      case 'PART_TIME':
        return 'Bán thời gian';
      case 'INTERN':
        return 'Thực tập';
      case 'COLLABORATOR':
        return 'Cộng tác viên';
      case 'TRY_JOB':
        return 'Thử việc';
      case 'OFFICIAL':
        return 'Chính thức';
      default:
        return str;
    }
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;
  final bool isDark;

  const _QuickStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s12, horizontal: AppTokens.s8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value?.isNotEmpty == true ? value! : 'Chính thức',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Theme.of(ctx).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final bool isDark;
  final BuildContext ctx;

  const _InfoSection(this.title, this.rows, this.isDark, this.ctx);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: AppTokens.s12),
            ...rows,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final BuildContext ctx;

  const _InfoRow(this.icon, this.label, this.value, this.ctx);

  @override
  Widget build(BuildContext _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: AppTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(ctx).textTheme.labelSmall),
                  Text(
                    value?.isNotEmpty == true ? value! : 'N/A',
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LeaveBalancesSection extends StatelessWidget {
  final List<LeaveBalanceEntity> leaveBalances;
  final bool isDark;
  final BuildContext ctx;

  const _LeaveBalancesSection({
    required this.leaveBalances,
    required this.isDark,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hạn mức ngày phép', style: Theme.of(ctx).textTheme.titleSmall),
              Text(
                '${leaveBalances.length} loại',
                style: const TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaveBalances.length,
            separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
            itemBuilder: (context, index) {
              final bal = leaveBalances[index];
              final total = bal.totalDays;
              final used = bal.usedDays;
              final remaining = bal.remainingDays;
              final totalStr = total % 1 == 0 ? total.toInt().toString() : total.toString();
              final usedStr = used % 1 == 0 ? used.toInt().toString() : used.toString();
              final remStr = remaining % 1 == 0 ? remaining.toInt().toString() : remaining.toString();

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bal.label,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đã dùng: $usedStr / $totalStr ngày',
                          style: TextStyle(fontSize: 12, color: Theme.of(ctx).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: remaining > 0
                          ? AppColors.success.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Còn $remStr',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: remaining > 0 ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}