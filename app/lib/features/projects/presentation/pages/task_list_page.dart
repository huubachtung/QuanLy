import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});
  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['Đang làm', 'Chưa làm', 'Hoàn thành', 'Đã huỷ'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<TaskModel> _filtered(List<TaskModel> all, int idx) {
    switch (idx) {
      case 0:
        return all.where((t) => t.status == TaskStatus.inProgress).toList();
      case 1:
        return all.where((t) => t.status == TaskStatus.todo).toList();
      case 2:
        return all.where((t) => t.status == TaskStatus.done).toList();
      case 3:
        return all.where((t) => t.status == TaskStatus.cancelled).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        final isLoading = state is ProjectsInitial || state is ProjectsLoading;
        List<TaskModel> myTasks = [];

        if (state is ProjectsLoaded) {
          myTasks = state.myTasks(currentUserId);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Công việc của tôi'),
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          body: isLoading
              ? ListView.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s8),
                      child: CardShimmer()))
              : AnimatedBuilder(
                  animation: _tabCtrl,
                  builder: (_, __) {
                    final list = _filtered(myTasks, _tabCtrl.index);
                    if (list.isEmpty) {
                      return const EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'Không có công việc nào');
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _TaskCard(task: list[i]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deadlineStr = task.deadlineDate != null
        ? DateFormat('dd/MM/yyyy').format(task.deadlineDate!)
        : 'N/A';
    final daysLeft = task.deadlineDate?.difference(DateTime.now()).inDays ?? 0;
    final isUrgent =
        daysLeft >= 0 && daysLeft <= 3 && task.status != TaskStatus.done;

    return InkWell(
      onTap: () => context.push('/tasks/${task.id}'),
      borderRadius: BorderRadius.circular(AppTokens.rCard),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s8),
        padding: const EdgeInsets.all(AppTokens.s16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(task.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppTokens.s8),
            StatusBadge.taskStatus(
                task.statusName.isNotEmpty ? task.statusName : task.status.label),
          ]),
          const SizedBox(height: AppTokens.s4),
          Text(task.projectName,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: AppTokens.s12),
          Row(children: [
            Flexible(
                child: _InfoItem(
                    Icons.flag_outlined,
                    task.priority,
                    task.priority == 'URGENT' || task.priority == 'HIGH'
                        ? AppColors.error
                        : AppColors.gold)),
            const SizedBox(width: AppTokens.s8),
            Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Flexible(
                  child: _InfoItem(
                      Icons.calendar_today_outlined,
                      deadlineStr,
                      isUrgent
                          ? AppColors.error
                          : Theme.of(context).textTheme.bodySmall?.color)),
              const SizedBox(width: AppTokens.s12),
              _InfoItem(Icons.trending_up_rounded, '${task.progress}%',
                  AppColors.success),
            ])),
          ]),
        ]),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoItem(this.icon, this.text, this.color);
  @override
  Widget build(BuildContext ctx) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: AppTokens.iconMicro, color: color),
        const SizedBox(width: AppTokens.s4),
        Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);
}
