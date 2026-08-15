import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app/features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/status_badge.dart';

class ProjectCalendarPage extends StatefulWidget {
  const ProjectCalendarPage({super.key});
  @override
  State<ProjectCalendarPage> createState() => _ProjectCalendarPageState();
}

class _ProjectCalendarPageState extends State<ProjectCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _onlyMyProjects = true;

  List<ProjectModel> _projectsForDay(List<ProjectModel> all, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return all.where((p) {
      final start =
          DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
      final end = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);
      return (target.isAfter(start) || isSameDay(target, start)) &&
          (target.isBefore(end) || isSameDay(target, end));
    }).toList();
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return AppColors.statusInProgress;
      case ProjectStatus.finished:
        return AppColors.statusFinished;
      case ProjectStatus.delayed:
        return AppColors.statusHold;
      default:
        return AppColors.statusNotStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        if (state is! ProjectsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProjects =
            _onlyMyProjects ? state.myProjects(currentUserId) : state.projects;

        final selectedProjects = _selectedDay != null
            ? _projectsForDay(allProjects, _selectedDay!)
            : _projectsForDay(allProjects, _focusedDay);

        return Column(children: [
          // Filter scope
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _onlyMyProjects = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _onlyMyProjects
                          ? AppColors.primaryBlue
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _onlyMyProjects
                            ? AppColors.primaryBlue
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Dự án của tôi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _onlyMyProjects
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.darkBg),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _onlyMyProjects = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_onlyMyProjects
                          ? AppColors.primaryBlue
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_onlyMyProjects
                            ? AppColors.primaryBlue
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tất cả (${state.projects.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: !_onlyMyProjects
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.darkBg),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          // Calendar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TableCalendar<ProjectModel>(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: (d) => _projectsForDay(allProjects, d),
              onDaySelected: (sel, foc) => setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              }),
              onPageChanged: (foc) => setState(() => _focusedDay = foc),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryBlue, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
                selectedTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
                defaultTextStyle: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkBg,
                    fontSize: 14),
                weekendTextStyle: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : AppColors.primaryBlue.withValues(alpha: 0.7)),
                markerDecoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
                markerSize: 6,
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.darkBg),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: isDark ? Colors.white70 : AppColors.primaryBlue),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: isDark ? Colors.white70 : AppColors.primaryBlue),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : AppColors.primaryBlue),
                weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppColors.primaryBlue.withValues(alpha: 0.5)),
              ),
            ),
          ),
          // Legend
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Legend(color: AppColors.statusInProgress, label: 'Đang làm'),
              SizedBox(width: 12),
              _Legend(color: AppColors.statusFinished, label: 'Hoàn thành'),
              SizedBox(width: 12),
              _Legend(color: AppColors.statusNotStarted, label: 'Chưa làm'),
              SizedBox(width: 12),
              _Legend(color: AppColors.statusHold, label: 'Trễ hạn'),
            ]),
          ),
          const SizedBox(height: 12),
          // Events for selected day
          if (selectedProjects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text(
                    _selectedDay != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                        : 'Hôm nay',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                StatusBadge(
                    label: '${selectedProjects.length} dự án',
                    color: AppColors.primaryBlue,
                    fontSize: 11),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
                child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedProjects.length,
              itemBuilder: (_, i) {
                final p = selectedProjects[i];
                final color = _statusColor(p.status);
                return GestureDetector(
                  onTap: () => context.push('/projects/${p.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(p.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          StatusBadge.projectStatus(p.status.label),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: LinearPercentIndicator(
                            lineHeight: 5,
                            percent: (p.progress / 100).clamp(0.0, 1.0),
                            progressColor: color,
                            backgroundColor: color.withValues(alpha: 0.15),
                            barRadius: const Radius.circular(3),
                            padding: EdgeInsets.zero,
                          )),
                          const SizedBox(width: 8),
                          Text('${p.progress.toInt()}%',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.date_range_outlined,
                              size: 13,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('dd/MM').format(p.startDate)} - ${DateFormat('dd/MM/yyyy').format(p.endDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          if (p.leaderName.isNotEmpty) ...[
                            Icon(Icons.person_outline_rounded,
                                size: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color),
                            const SizedBox(width: 4),
                            Text(p.leaderName,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ]),
                      ],
                    ),
                  ),
                );
              },
            )),
          ] else
            Expanded(
                child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_available_rounded,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Text('Không có dự án nào trong ngày này',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            )),
        ]);
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext ctx) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Theme.of(ctx).textTheme.bodySmall?.color)),
      ]);
}
