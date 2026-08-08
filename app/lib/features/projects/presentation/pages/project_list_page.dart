import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
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
    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final isLoading = state is ProjectsInitial || state is ProjectsLoading;
        List<ProjectModel> allProjects = [];
        int inProg = 0, todo = 0, done = 0;
        
        if (state is ProjectsLoaded) {
          allProjects = state.projects;
          final myTasks = state.myTasks;
          inProg = myTasks.where((t) => t.status == TaskStatus.inProgress).length;
          todo = myTasks.where((t) => t.status == TaskStatus.todo).length;
          done = myTasks.where((t) => t.status == TaskStatus.done).length;
        }

        return Column(children: [
          // Navigation shortcuts
          _buildNavShortcuts(context),
          // Task quick stats
          if (!isLoading) _buildTaskStats(context, inProg, todo, done),
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
            child: isLoading
              ? ListView.builder(itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: CardShimmer()))
              : AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (_, __) {
                    final list = _filtered(allProjects, _tabCtrl.index);
                    if (list.isEmpty) {
                      return const EmptyState(icon: Icons.folder_off_rounded, title: 'Không có dự án nào');
                    }
                    return ListView.builder(
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
        ]);
      },
    );
  }

  Widget _buildNavShortcuts(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: _ShortcutBtn('Công việc', Icons.task_alt_rounded, () => context.push('/tasks'), isDark)),
        const SizedBox(width: 8),
        Expanded(child: _ShortcutBtn('Timeline', Icons.timeline_rounded, () => context.push('/timeline'), isDark)),
      ]),
    );
  }

  Widget _buildTaskStats(BuildContext context, int inProg, int todo, int done) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF1E4A9A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: _StatItem(label: 'Đang làm', value: '$inProg', color: AppColors.gold)),
        _VertDivider(),
        Expanded(child: _StatItem(label: 'Chưa làm', value: '$todo', color: Colors.white70)),
        _VertDivider(),
        Expanded(child: _StatItem(label: 'Hoàn thành', value: '$done', color: AppColors.success)),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override Widget build(BuildContext ctx) =>
    Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2));
}

class _ShortcutBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _ShortcutBtn(this.label, this.icon, this.onTap, this.isDark);
  @override Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
  @override Widget build(BuildContext ctx) => Column(children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  ]);
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final List<TaskModel> tasks;
  const _ProjectCard({required this.project, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysLeft = project.endDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0 && project.status != ProjectStatus.finished;
    Color statusColor;
    switch (project.status) {
      case ProjectStatus.inProgress: statusColor = AppColors.statusInProgress; break;
      case ProjectStatus.finished: statusColor = AppColors.statusFinished; break;
      case ProjectStatus.delayed: statusColor = AppColors.statusDelayed; break;
      default: statusColor = AppColors.statusNotStarted;
    }
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(project.name,
              style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            StatusBadge.projectStatus(project.status.label),
          ]),
          const SizedBox(height: 6),
          Text(project.description,
            style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          // Progress bar
          Row(children: [
            Expanded(child: LinearPercentIndicator(
              lineHeight: 6, percent: project.progress / 100,
              progressColor: statusColor,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
            )),
            const SizedBox(width: 10),
            Text('${project.progress.toInt()}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Row(children: [
              Icon(Icons.person_outline_rounded, size: 14,
                color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Expanded(child: Text(project.leaderName, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            ])),
            const SizedBox(width: 8),
            Row(children: [
              Icon(Icons.task_alt_rounded, size: 14,
                color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text('${tasks.length} task', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 14,
                color: isOverdue ? AppColors.error : Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(isOverdue ? 'Trễ ${daysLeft.abs()}' : 'Còn $daysLeft',
                style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.error : null)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
