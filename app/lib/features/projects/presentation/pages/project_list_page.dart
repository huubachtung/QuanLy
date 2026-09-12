import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_event.dart';
import '../bloc/projects_state.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/empty_state.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});
  @override State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['Tất cả', 'Đang làm', 'Hoàn thành', 'Trễ hạn', 'Chưa làm'];
  bool _onlyMyProjects = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    // Load data khi trang mở (sau khi đã đăng nhập)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProjectsBloc>().state;
      if (state is ProjectsInitial) {
        context.read<ProjectsBloc>().add(const LoadProjectsData());
      }
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<ProjectModel> _filtered(List<ProjectModel> all, int idx) {
    switch (idx) {
      case 1: return all.where((p) => p.status == ProjectStatus.inProgress).toList();
      case 2: return all.where((p) => p.status == ProjectStatus.finished).toList();
      case 3: return all.where((p) => p.status == ProjectStatus.delayed).toList();
      case 4: return all.where((p) => p.status == ProjectStatus.notStarted).toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final isLoading = state is ProjectsInitial || state is ProjectsLoading;
        List<ProjectModel> displayProjects = [];
        int inProg = 0, todo = 0, done = 0;
        
        if (state is ProjectsLoaded) {
          final myProj = state.myProjects(currentUserId);
          displayProjects = _onlyMyProjects ? myProj : state.projects;
          inProg = displayProjects.where((p) => p.status == ProjectStatus.inProgress).length;
          todo = displayProjects.where((p) => p.status == ProjectStatus.notStarted).length;
          done = displayProjects.where((p) => p.status == ProjectStatus.finished).length;
        }

        if (state is ProjectsError) {
          return RefreshIndicator(
            onRefresh: () async {
              final completer = Completer<void>();
              context.read<ProjectsBloc>().add(LoadProjectsData(completer: completer));
              return completer.future;
            },
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.s24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                          const SizedBox(height: AppTokens.s12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTokens.s16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<ProjectsBloc>().add(const LoadProjectsData()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Column(children: [
          // Navigation shortcuts
          _buildNavShortcuts(context),
          // Project stats card
          if (!isLoading) _buildProjectStats(context, inProg, todo, done),
          // Filter scope toggle (Của tôi / Tất cả)
          if (!isLoading && state is ProjectsLoaded)
            _buildScopeSelector(context, state.myProjects(currentUserId).length, state.projects.length),
          // Tab bar
          Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final completer = Completer<void>();
                context.read<ProjectsBloc>().add(LoadProjectsData(completer: completer));
                return completer.future;
              },
              child: isLoading
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: CardShimmer(),
                    ),
                  )
                : AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (_, __) {
                      final list = _filtered(displayProjects, _tabCtrl.index);
                      if (list.isEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: EmptyState(
                                  icon: Icons.folder_off_rounded,
                                  title: _onlyMyProjects
                                    ? 'Bạn chưa tham gia dự án nào trong mục này'
                                    : 'Không có dự án nào',
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final p = list[i];
                          final tasks = state is ProjectsLoaded ? state.tasksForProject(p.id) : <TaskModel>[];
                          return _ProjectCard(project: p, tasks: tasks);
                        },
                      );
                    },
                  ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildScopeSelector(BuildContext context, int myCount, int totalCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s8, AppTokens.s16, AppTokens.s4),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _onlyMyProjects = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
              decoration: BoxDecoration(
                color: _onlyMyProjects
                    ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppTokens.rInput),
                border: Border.all(
                  color: _onlyMyProjects
                      ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Center(
                child: Text(
                  'Của tôi ($myCount)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _onlyMyProjects ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBg),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _onlyMyProjects = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
              decoration: BoxDecoration(
                color: !_onlyMyProjects
                    ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(AppTokens.rInput),
                border: Border.all(
                  color: !_onlyMyProjects
                      ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Center(
                child: Text(
                  'Tất cả dự án ($totalCount)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !_onlyMyProjects ? Colors.white : (isDark ? Colors.white70 : AppColors.darkBg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildNavShortcuts(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12, AppTokens.s16, 0),
      child: Row(children: [
        Expanded(child: _ShortcutBtn('Công việc', Icons.assignment_outlined, () => context.push('/tasks'), isDark)),
        const SizedBox(width: AppTokens.s8),
        Expanded(child: _ShortcutBtn('Timeline', Icons.timeline_rounded, () => context.push('/timeline'), isDark)),
      ]),
    );
  }

  Widget _buildProjectStats(BuildContext context, int inProg, int todo, int done) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTokens.s16, AppTokens.s12, AppTokens.s16, 0),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Expanded(child: _StatItem(label: 'Đang làm', value: '$inProg', color: AppColors.gold, isDark: isDark)),
        _VertDivider(isDark: isDark),
        Expanded(child: _StatItem(label: 'Chưa làm', value: '$todo', color: isDark ? Colors.white70 : const Color(0xFF64748B), isDark: isDark)),
        _VertDivider(isDark: isDark),
        Expanded(child: _StatItem(label: 'Hoàn thành', value: '$done', color: AppColors.success, isDark: isDark)),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  final bool isDark;
  const _VertDivider({required this.isDark});
  @override Widget build(BuildContext ctx) =>
    Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
}

class _ShortcutBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _ShortcutBtn(this.label, this.icon, this.onTap, this.isDark);
  @override Widget build(BuildContext ctx) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTokens.rInput),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rInput),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: AppTokens.iconMicro + 2, color: Theme.of(ctx).colorScheme.primary),
        const SizedBox(width: AppTokens.s8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatItem({required this.label, required this.value, required this.color, required this.isDark});
  @override Widget build(BuildContext ctx) => Column(children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, color: color)),
    const SizedBox(height: AppTokens.s4),
    Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
  ]);
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final List<TaskModel> tasks;
  const _ProjectCard({required this.project, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(project.endDate.year, project.endDate.month, project.endDate.day);
    final daysLeft = endDay.difference(today).inDays;

    final String deadlineText;
    final Color deadlineColor;
    final IconData deadlineIcon;

    if (project.status == ProjectStatus.finished) {
      deadlineText = 'Hoàn thành';
      deadlineColor = AppColors.statusFinished;
      deadlineIcon = Icons.check_circle_outline_rounded;
    } else if (daysLeft < 0) {
      deadlineText = 'Trễ ${daysLeft.abs()} ngày';
      deadlineColor = AppColors.error;
      deadlineIcon = Icons.schedule_rounded;
    } else if (daysLeft == 0) {
      deadlineText = 'Hạn hôm nay';
      deadlineColor = AppColors.warning;
      deadlineIcon = Icons.schedule_rounded;
    } else {
      deadlineText = 'Còn $daysLeft ngày';
      deadlineColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.statusNotStarted;
      deadlineIcon = Icons.schedule_rounded;
    }

    Color statusColor;
    switch (project.status) {
      case ProjectStatus.inProgress: statusColor = AppColors.statusInProgress; break;
      case ProjectStatus.finished: statusColor = AppColors.statusFinished; break;
      case ProjectStatus.delayed: statusColor = AppColors.statusDelayed; break;
      default: statusColor = AppColors.statusNotStarted;
    }
    return InkWell(
      onTap: () => context.push('/projects/${project.id}'),
      borderRadius: BorderRadius.circular(AppTokens.rCard),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s8),
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(project.name,
              style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppTokens.s8),
            StatusBadge.projectStatus(project.status.label),
          ]),
          const SizedBox(height: AppTokens.s8),
          Text(project.description,
            style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppTokens.s12),
          // Progress bar
          Row(children: [
            Expanded(child: LinearPercentIndicator(
              lineHeight: 6, percent: (project.progress / 100).clamp(0.0, 1.0),
              progressColor: statusColor,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              barRadius: const Radius.circular(3),
              padding: EdgeInsets.zero,
            )),
            const SizedBox(width: AppTokens.s8),
            Text('${project.progress.toInt()}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
          ]),
          const SizedBox(height: AppTokens.s12),
          Row(children: [
            Expanded(child: Row(children: [
              Icon(Icons.person_outline_rounded, size: AppTokens.iconMicro,
                color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: AppTokens.s4),
              Expanded(child: Text(project.leaderName, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            ])),
            const SizedBox(width: AppTokens.s8),
            Row(children: [
              Icon(Icons.assignment_outlined, size: AppTokens.iconMicro,
                color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: AppTokens.s4),
              Text('${tasks.length} task', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: AppTokens.s12),
              Icon(deadlineIcon, size: AppTokens.iconMicro, color: deadlineColor),
              const SizedBox(width: AppTokens.s4),
              Text(deadlineText,
                style: TextStyle(fontSize: 12, color: deadlineColor)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
