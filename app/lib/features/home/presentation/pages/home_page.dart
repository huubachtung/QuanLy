import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import 'package:app/core/widgets/app_avatar.dart';
import 'package:app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/providers/theme_provider.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tabs = [
    (
      label: 'Dự án',
      idleIcon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      path: '/projects'
    ),
    (
      label: 'Lịch',
      idleIcon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_month_rounded,
      path: '/calendar'
    ),
    (
      label: 'Thông báo',
      idleIcon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      path: '/notifications'
    ),
    (
      label: 'Chấm công',
      idleIcon: Icons.fingerprint_rounded,
      activeIcon: Icons.fingerprint_rounded,
      path: '/attendance'
    ),
    (
      label: 'Yêu cầu',
      idleIcon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      path: '/requests'
    ),
  ];

  void _onTabTap(BuildContext context, int idx) {
    context.read<HomeBloc>().add(ChangeTabEvent(idx));
    context.go(_tabs[idx].path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    final idx =
        _tabs.indexWhere((t) => t.path == loc || loc.startsWith('${t.path}/'));
    if (idx != -1) {
      final currentIdx = context.read<HomeBloc>().state.currentIndex;
      if (idx != currentIdx) {
        context.read<HomeBloc>().add(ChangeTabEvent(idx));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return PopScope(
      canPop: loc != '/profile',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (loc == '/profile') {
          final currentIdx = context.read<HomeBloc>().state.currentIndex;
          final prevTab = (currentIdx >= 0 && currentIdx < _tabs.length)
              ? _tabs[currentIdx].path
              : '/projects';
          context.go(prevTab);
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context, isDark),
        body: widget.child,
        bottomNavigationBar: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final currentIdx = state.currentIndex;
            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s8,
                    vertical: AppTokens.s4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_tabs.length, (i) {
                      final isSelected = currentIdx == i;
                      final tab = _tabs[i];
                      final color = isSelected
                          ? (isDark
                              ? AppColors.primaryLight
                              : AppColors.primaryBlue)
                          : (isDark
                              ? const Color(0xFF8FA3C8)
                              : const Color(0xFF64748B));

                      Widget iconWidget = Icon(
                        isSelected ? tab.activeIcon : tab.idleIcon,
                        size: AppTokens.iconAction + 2,
                        color: color,
                      );

                      // Badge for notifications
                      if (i == 2) {
                        final baseIcon = iconWidget;
                        iconWidget =
                            BlocBuilder<NotificationBloc, NotificationState>(
                                builder: (_, notifState) {
                          int unreadCount = 0;
                          if (notifState is NotificationLoaded) {
                            unreadCount = notifState.unreadCount;
                          }
                          return unreadCount > 0
                              ? badges.Badge(
                                  badgeContent: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  badgeStyle: const badges.BadgeStyle(
                                    badgeColor: AppColors.error,
                                    padding: EdgeInsets.all(AppTokens.s4),
                                  ),
                                  child: baseIcon,
                                )
                              : baseIcon;
                        });
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onTabTap(context, i),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: AppTokens.animNormal,
                            curve: AppTokens.curveDefault,
                            padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primaryLight.withValues(alpha: 0.12)
                                      : AppColors.primaryBlue.withValues(alpha: 0.08))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTokens.rInput),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                iconWidget,
                                const SizedBox(height: AppTokens.s4),
                                Text(
                                  tab.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    letterSpacing: 0.2,
                                    color: color,
                                  ),
                                ),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final loc = GoRouterState.of(context).matchedLocation;
    String title = 'Juss_TV';
    if (loc.startsWith('/projects') && loc != '/projects') {
      title = 'Chi tiết Dự án';
    } else if (loc == '/projects' || loc == '/') {
      title = 'Dự án của tôi';
    } else if (loc.startsWith('/tasks')) {
      title = 'Chi tiết Task';
    } else if (loc == '/calendar') {
      title = 'Lịch đẩy dự án';
    } else if (loc == '/notifications') {
      title = 'Thông báo';
    } else if (loc == '/attendance') {
      title = 'Bảng chấm công';
    } else if (loc == '/leave') {
      title = 'Xin nghỉ phép';
    } else if (loc == '/overtime') {
      title = 'Kê khai tăng ca';
    } else if (loc == '/requests') {
      title = 'Yêu cầu cá nhân';
    } else if (loc.startsWith('/assets')) {
      title = 'Tài sản';
    } else if (loc == '/profile') {
      title = 'Hồ sơ cá nhân';
    }

    return AppBar(
      leading: loc == '/profile'
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Quay lại',
              onPressed: () {
                final currentIdx = context.read<HomeBloc>().state.currentIndex;
                final prevTab = (currentIdx >= 0 && currentIdx < _tabs.length)
                    ? _tabs[currentIdx].path
                    : '/projects';
                context.go(prevTab);
              },
            )
          : Row(
              children: [
                const SizedBox(width: AppTokens.s12),
                Image.asset('assets/images/Logo.png', width: 28, height: 28),
              ],
            ),
      leadingWidth: loc == '/profile' ? 44 : 48,
      title: Text(title),
      actions: [
        Consumer<ThemeProvider>(
          builder: (_, tp, __) => IconButton(
            onPressed: tp.toggleTheme,
            icon: Icon(
              tp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? AppColors.gold : AppColors.primaryBlue,
              size: AppTokens.iconAction,
            ),
            tooltip: tp.isDark ? 'Chế độ sáng' : 'Chế độ tối',
          ),
        ),
        if (loc != '/profile')
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return AppAvatar(
                    avatarUrl: state.user.avatar,
                    name: state.user.displayName.isNotEmpty
                        ? state.user.displayName
                        : state.user.username,
                    radius: 14,
                    fontSize: 10,
                  );
                }
                return const AppAvatar(
                  radius: 14,
                  fontSize: 10,
                );
              },
            ),
          ),
        const SizedBox(width: AppTokens.s4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
    );
  }
}
