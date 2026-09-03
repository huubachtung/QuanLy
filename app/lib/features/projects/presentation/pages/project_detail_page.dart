import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
import '../../../../shared/widgets/status_badge.dart';

class ProjectDetailPage extends StatelessWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        if (state is! ProjectsLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final project = state.projects.firstWhere((p) => p.id == projectId, orElse: () => state.projects.first);
        final tasks = state.tasksForProject(projectId);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(project.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
                      StatusBadge.projectStatus(project.status.label),
                    ]),
                    const SizedBox(height: 10),
                    Text(project.description,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 36, lineWidth: 6, percent: project.progress / 100,
                      progressColor: AppColors.gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      center: Text('${project.progress.toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      _InfoChip(Icons.person_outline_rounded, project.leaderName),
                      const SizedBox(width: 12),
                      _InfoChip(Icons.calendar_today_rounded,
                        '${DateFormat('dd/MM/yy').format(project.startDate)} - ${DateFormat('dd/MM/yy').format(project.endDate)}'),
                    ]),
                  ]),
                ),
                // Tasks section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text('Công việc (${tasks.length})',
                    style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            )),
            SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final t = tasks[i];
                return _TaskRow(task: t, isDark: isDark);
              },
              childCount: tasks.length,
            )),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ]),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);
  @override Widget build(BuildContext ctx) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: Colors.white70),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70)),
  ]);
}

class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  const _TaskRow({required this.task, required this.isDark});

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.inProgress: return AppColors.statusInProgress;
      case TaskStatus.done: return AppColors.statusFinished;
      case TaskStatus.cancelled: return AppColors.statusCancelled;
      default: return AppColors.statusNotStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tasks/${task.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          // Priority indicator
          Container(width: 4, height: 44, decoration: BoxDecoration(
            color: _statusColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.name, style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              StatusBadge(
                  label: task.statusName.isNotEmpty
                      ? task.statusName
                      : task.status.label,
                  color: _statusColor,
                  fontSize: 10,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
              const SizedBox(width: 8),
              if (task.deadlineDate != null)
                Text(DateFormat('dd/MM').format(task.deadlineDate!),
                  style: Theme.of(context).textTheme.labelSmall),
            ]),
          ])),
          const SizedBox(width: 8),
          Text('${task.progress.toInt()}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor)),
        ]),
      ),
    );
  }
}
