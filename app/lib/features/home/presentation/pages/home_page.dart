import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // Giữ tạm cho NotificationProvider và ThemeProvider
import 'package:badges/badges.dart' as badges;
import 'package:app/core/utils/app_colors.dart';
import 'package:app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:app/features/notifications/presentation/bloc/notification_state.dart';
import '../../../../core/providers/theme_provider.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = [
    (label: 'Dự án', icon: 'assets/images/project.png', path: '/projects'),
    (label: 'Lịch', icon: Icons.calendar_month_rounded, path: '/calendar'),
    (label: 'Thông báo', icon: Icons.notifications_rounded, path: '/notifications'),
    (label: 'Chấm công', icon: Icons.fingerprint_rounded, path: '/attendance'),
    (label: 'Yêu cầu', icon: Icons.assignment_rounded, path: '/requests'),
  ];

  void _onTabTap(BuildContext context, int idx) {
    context.read<HomeBloc>().add(ChangeTabEvent(idx));
    context.go(_tabs[idx].path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => t.path == loc || loc.startsWith(t.path + '/'));
    if (idx != -1) {
      final currentIdx = context.read<HomeBloc>().state.currentIndex;
      if (idx != currentIdx) {
        context.read<HomeBloc>().add(ChangeTabEvent(idx));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      appBar: _buildAppBar(context, isDark),
      body: widget.child,
      bottomNavigationBar: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final _currentIdx = state.currentIndex;
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length, (i) {
                    final isSelected = _currentIdx == i;
                    final tab = _tabs[i];
                    final color = isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                        : (isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8));
                    Widget iconWidget = tab.icon is String
                      ? Image.asset(tab.icon as String, width: 24, height: 24, color: color)
                      : Icon(tab.icon as IconData, size: 24, color: color);
                      // Badge for notifications
                      if (i == 2) {
                        final baseIcon = iconWidget;
                        iconWidget = BlocBuilder<NotificationBloc, NotificationState>(
                          builder: (_, state) {
                            int unreadCount = 0;
                            if (state is NotificationLoaded) {
                              unreadCount = state.unreadCount;
                            }
                            return unreadCount > 0
                            ? badges.Badge(
                                badgeContent: Text('$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.error, padding: EdgeInsets.all(4)),
                                child: baseIcon)
                            : baseIcon;
                          }
                        );
                      }
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabTap(context, i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? (isDark ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryBlue.withValues(alpha: 0.08))
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              iconWidget,
                              const SizedBox(height: 3),
                              Text(tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                    ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                                    : (isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8)),
                                )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final loc = GoRouterState.of(context).matchedLocation;
    String title = 'Juss_TV';
    if (loc.startsWith('/projects') && loc != '/projects') title = 'Chi tiết Dự án';
    else if (loc == '/projects' || loc == '/') title = 'Dự án của tôi';
    else if (loc.startsWith('/tasks')) title = 'Chi tiết Task';
    else if (loc == '/calendar') title = 'Lịch đẩy dự án';
    else if (loc == '/notifications') title = 'Thông báo';
    else if (loc == '/attendance') title = 'Bảng chấm công';
    else if (loc == '/leave') title = 'Xin nghỉ phép';
    else if (loc == '/overtime') title = 'Kê khai tăng ca';
    else if (loc == '/requests') title = 'Yêu cầu cá nhân';
    else if (loc.startsWith('/assets')) title = 'Tài sản';
    else if (loc == '/profile') title = 'Hồ sơ cá nhân';

    return AppBar(
      leading: Row(
        children: [
          const SizedBox(width: 12),
          Image.asset('assets/images/Logo.png', width: 32, height: 32),
        ],
      ),
      leadingWidth: 52,
      title: Text(title),
      actions: [
        Consumer<ThemeProvider>(
          builder: (_, tp, __) => IconButton(
            onPressed: tp.toggleTheme,
            icon: Icon(tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.gold : AppColors.primaryBlue, size: 22),
            tooltip: tp.isDark ? 'Chế độ sáng' : 'Chế độ tối',
          ),
        ),
        IconButton(
          onPressed: () => context.go('/profile'),
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: isDark ? AppColors.primaryBlue : AppColors.primaryBlue.withValues(alpha: 0.1),
            child: Text('NVA',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.primaryBlue,
              )),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }
}
