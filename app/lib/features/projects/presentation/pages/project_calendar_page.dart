import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_state.dart';
import '../../../../shared/widgets/status_badge.dart';

class ProjectCalendarPage extends StatefulWidget {
  const ProjectCalendarPage({super.key});
  @override State<ProjectCalendarPage> createState() => _ProjectCalendarPageState();
}

class _ProjectCalendarPageState extends State<ProjectCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<ProjectScheduleModel> _eventsForDay(List<ProjectScheduleModel> all, DateTime day) {
    return all.where((s) => isSameDay(s.scheduledDate, day)).toList();
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress: return AppColors.statusInProgress;
      case ProjectStatus.finished: return AppColors.statusFinished;
      case ProjectStatus.delayed: return AppColors.statusHold;
      default: return AppColors.statusNotStarted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, state) {
        if (state is! ProjectsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final schedules = state.schedules;
        final selectedEvents = _selectedDay != null
          ? _eventsForDay(schedules, _selectedDay!)
          : _eventsForDay(schedules, _focusedDay);

        return Column(children: [
          // Calendar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TableCalendar<ProjectScheduleModel>(
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              eventLoader: (d) => _eventsForDay(schedules, d),
              onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }),
              onPageChanged: (foc) => setState(() => _focusedDay = foc),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primaryBlue, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                defaultTextStyle: TextStyle(color: isDark ? Colors.white : AppColors.darkBg, fontSize: 14),
                weekendTextStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.primaryBlue.withValues(alpha: 0.7)),
                markerDecoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                markerSize: 6, markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false, titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkBg),
                leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white70 : AppColors.primaryBlue),
                rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white70 : AppColors.primaryBlue),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.primaryBlue),
                weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.primaryBlue.withValues(alpha: 0.5)),
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Legend(color: AppColors.statusInProgress, label: 'Đang làm'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.statusFinished, label: 'Hoàn thành'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.statusHold, label: 'Bị trì hoãn'),
            ]),
          ),
          const SizedBox(height: 12),
          // Events for selected day
          if (selectedEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text(_selectedDay != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                  : 'Hôm nay',
                  style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 8),
                StatusBadge(label: '${selectedEvents.length} sự kiện', color: AppColors.primaryBlue, fontSize: 11),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedEvents.length,
              itemBuilder: (_, i) {
                final ev = selectedEvents[i];
                final color = _statusColor(ev.projectStatus);
                return GestureDetector(
                  onTap: () => _showProjectSheet(context, ev, isDark),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Container(width: 4, height: 40, decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ev.projectName, style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        StatusBadge.projectStatus(ev.projectStatus.label),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ]),
                  ),
                );
              },
            )),
          ] else
            Expanded(child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_available_rounded, size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Text('Không có sự kiện', style: Theme.of(context).textTheme.bodySmall),
              ]),
            )),
        ]);
      },
    );
  }

  void _showProjectSheet(BuildContext context, ProjectScheduleModel ev, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(ev.projectName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          StatusBadge.projectStatus(ev.projectStatus.label),
          const SizedBox(height: 12),
          Text(ev.projectDescription, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 6),
            Text('Ngày đẩy: ${DateFormat('dd/MM/yyyy').format(ev.scheduledDate)}',
              style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override Widget build(BuildContext ctx) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(ctx).textTheme.bodySmall?.color)),
  ]);
}
