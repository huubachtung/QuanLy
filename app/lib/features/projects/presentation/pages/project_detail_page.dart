import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
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
        if (state is! ProjectsLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final project = state.projects.firstWhere(
          (p) => p.id == projectId,
          orElse: () => state.projects.first,
        );
        final tasks = state.tasksForProject(projectId);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết dự án'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      margin: const EdgeInsets.all(AppTokens.s16),
                      padding: const EdgeInsets.all(AppTokens.s16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTokens.rCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppTokens.s8),
                              StatusBadge.projectStatus(project.status.label),
                            ],
                          ),
                          if (project.description.isNotEmpty) ...[
                            const SizedBox(height: AppTokens.s8),
                            Text(
                              project.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppTokens.s16),
                          Row(
                            children: [
                              CircularPercentIndicator(
                                radius: 32,
                                lineWidth: 5,
                                percent: (project.progress / 100).clamp(0.0, 1.0),
                                progressColor: AppColors.gold,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                center: Text(
                                  '${project.progress.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.s16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (project.leaderName.isNotEmpty)
                                      _InfoChip(
                                        Icons.person_outline_rounded,
                                        project.leaderName,
                                      ),
                                    const SizedBox(height: AppTokens.s8),
                                    _InfoChip(
                                      Icons.calendar_today_rounded,
                                      '${DateFormat('dd/MM/yy').format(project.startDate)} - ${DateFormat('dd/MM/yy').format(project.endDate)}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Tasks section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.s16,
                        AppTokens.s8,
                        AppTokens.s16,
                        AppTokens.s8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Công việc',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          StatusBadge(
                            label: '${tasks.length}',
                            color: AppColors.primaryBlue,
                            fontSize: 11,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (tasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.s32),
                    child: Center(
                      child: Text(
                        'Chưa có công việc nào',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _TaskRow(task: tasks[i], isDark: isDark),
                    childCount: tasks.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppTokens.s24)),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext ctx) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: AppTokens.s4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  const _TaskRow({required this.task, required this.isDark});

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.done:
        return AppColors.statusFinished;
      case TaskStatus.cancelled:
        return AppColors.statusCancelled;
      default:
        return AppColors.statusNotStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppTokens.rCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          onTap: () => context.push('/tasks/${task.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Row(
                        children: [
                          StatusBadge(
                            label: task.statusName.isNotEmpty
                                ? task.statusName
                                : task.status.label,
                            color: _statusColor,
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s8,
                              vertical: 2,
                            ),
                          ),
                          const SizedBox(width: AppTokens.s8),
                          if (task.deadlineDate != null) ...[
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: AppTokens.s4),
                            Text(
                              DateFormat('dd/MM').format(task.deadlineDate!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.s8),
                Text(
                  '${task.progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
