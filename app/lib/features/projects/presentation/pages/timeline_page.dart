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

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});
  @override State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final _scrollCtrl = ScrollController();
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 15));
  final int _dayCount = 60;
  final double _dayWidth = 60.0;
  final double _rowHeight = 64.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCtrl.jumpTo(15 * _dayWidth - 100);
    });
  }

  @override void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Tiến độ công việc (Timeline)')),
      body: BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          if (state is ProjectsInitial || state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = state is ProjectsLoaded ? state.myTasks(currentUserId) : <TaskModel>[];
          
          return Column(
            children: [
              // Date Header
              _buildDateHeader(isDark),
              // Timeline Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _dayCount * _dayWidth,
                      height: tasks.length * _rowHeight + 100,
                      child: Stack(
                        children: [
                          // Vertical grid lines
                          ...List.generate(_dayCount, (i) => Positioned(
                            left: i * _dayWidth,
                            top: 0, bottom: 0,
                            child: VerticalDivider(
                              width: 1,
                              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.6),
                            ),
                          )),
                          // Task Rows
                          ...List.generate(tasks.length, (i) {
                            final task = tasks[i];
                            final DateTime taskStart = task.startDate ?? DateTime.now();
                            final DateTime taskEnd = task.deadlineDate ?? taskStart.add(const Duration(days: 1));
                            
                            // Calculate position
                            final double startOffset = taskStart.difference(_startDate).inDays.toDouble() * _dayWidth;
                            final int durationDays = taskEnd.difference(taskStart).inDays + 1;
                            final double width = (durationDays.toDouble() * _dayWidth).clamp(32.0, double.infinity);
                            final color = _getStatusColor(task.status);
                            
                            return Positioned(
                              top: i * _rowHeight + AppTokens.s16,
                              left: 0,
                              right: 0,
                              child: SizedBox(
                                height: _rowHeight,
                                child: Stack(
                                  children: [
                                    // Task bar background
                                    Positioned(
                                      left: startOffset,
                                      width: width,
                                      height: 32,
                                      child: GestureDetector(
                                        onTap: () => context.push('/tasks/${task.id}'),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppTokens.rMicro),
                                            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
                                          child: Text(
                                            task.name, 
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : AppColors.darkBg,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Progress indicator inside bar
                                    Positioned(
                                      left: startOffset,
                                      width: (width * (task.progress / 100)).clamp(0.0, width),
                                      height: 32,
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(AppTokens.rMicro),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Label overlay (to keep progress readable)
                                    Positioned(
                                      left: startOffset,
                                      width: width,
                                      height: 32,
                                      child: IgnorePointer(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: AppTokens.s8),
                                            child: Text(
                                              '${task.progress.toInt()}%',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white70 : color,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Current day vertical line
                          Positioned(
                            left: DateTime.now().difference(_startDate).inDays * _dayWidth + (DateTime.now().hour / 24 * _dayWidth),
                            top: 0, bottom: 0,
                            child: Container(width: 2, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(bool isDark) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_dayCount, (i) {
            final date = _startDate.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            return Container(
              width: _dayWidth,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date), 
                    style: TextStyle(fontSize: 10, color: isToday ? AppColors.error : Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.error : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(date.day.toString(), 
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      )),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress: return AppColors.statusInProgress;
      case TaskStatus.done: return AppColors.statusFinished;
      case TaskStatus.cancelled: return AppColors.statusDelayed;
      default: return AppColors.statusNotStarted;
    }
  }
}
