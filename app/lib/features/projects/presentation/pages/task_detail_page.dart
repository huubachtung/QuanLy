import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import '../../../../core/models/project_model.dart';
import '../bloc/projects_bloc.dart';
import '../bloc/projects_event.dart';
import '../bloc/projects_state.dart';
import '../../../../shared/widgets/status_badge.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});
  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  double _progress = 0;
  TaskStatus? _status;
  String? _selectedStepId;
  bool _saving = false;
  bool _initialized = false;

  void _save(BuildContext context, TaskModel task) {
    if (_saving) return;
    setState(() => _saving = true);

    context.read<ProjectsBloc>().add(UpdateTaskProgressEvent(
          taskId: widget.taskId,
          progress: _progress,
          status: _status,
          toStepId: (_selectedStepId != null &&
                  _selectedStepId != task.currentStepId)
              ? _selectedStepId
              : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (_saving) {
          if (state is ProjectsLoaded) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Cập nhật tiến độ task thành công'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ));
          } else if (state is ProjectsError) {
            setState(() => _saving = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('❌ Lỗi cập nhật: ${state.message}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ));
          }
        }
      },
      builder: (context, state) {
        if (state is! ProjectsLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final taskIndex =
            state.tasks.indexWhere((t) => t.id == widget.taskId);
        if (taskIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết công việc')),
            body: const Center(child: Text('Không tìm thấy công việc này')),
          );
        }

        final task = state.tasks[taskIndex];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (!_initialized) {
          _progress = task.progress;
          _status = task.status;
          _selectedStepId = task.currentStepId;
          _initialized = true;
        }

        Color priorityColor;
        switch (task.priority) {
          case 'URGENT':
            priorityColor = AppColors.error;
            break;
          case 'HIGH':
            priorityColor = AppColors.warning;
            break;
          case 'MEDIUM':
            priorityColor = AppColors.info;
            break;
          default:
            priorityColor = AppColors.statusNotStarted;
        }
        String priorityLabel;
        switch (task.priority) {
          case 'URGENT':
            priorityLabel = 'Khẩn cấp';
            break;
          case 'HIGH':
            priorityLabel = 'Cao';
            break;
          case 'MEDIUM':
            priorityLabel = 'Trung bình';
            break;
          default:
            priorityLabel = 'Thấp';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết công việc'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Task header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(task.name,
                                style:
                                    Theme.of(context).textTheme.headlineSmall)),
                        StatusBadge(
                            label: priorityLabel,
                            color: priorityColor,
                            fontSize: 11),
                      ]),
                      const SizedBox(height: 8),
                      if (task.description.isNotEmpty) ...[
                        Text(task.description,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],
                      // Info rows
                      _InfoRow(
                          icon: Icons.folder_outlined,
                          label: 'Dự án',
                          value: task.projectName),
                      const SizedBox(height: 6),
                      _InfoRow(
                          icon: Icons.assignment_turned_in_outlined,
                          label: 'Trạng thái',
                          value: task.statusName.isNotEmpty
                              ? task.statusName
                              : task.status.label,
                          valueColor: AppColors.primaryBlue),
                      const SizedBox(height: 6),
                      _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Người giao',
                          value: task.reporterName),
                      if (task.assignedToName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                            icon: Icons.person_pin_circle_outlined,
                            label: 'Người thực hiện',
                            value: task.assignedToName),
                      ],
                      if (task.deadlineDate != null) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                            icon: Icons.schedule_rounded,
                            label: 'Deadline',
                            value: DateFormat('dd/MM/yyyy')
                                .format(task.deadlineDate!),
                            valueColor:
                                task.deadlineDate!.isBefore(DateTime.now()) &&
                                        task.status != TaskStatus.done
                                    ? AppColors.error
                                    : null),
                      ],
                      if (task.requiredSkill.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _InfoRow(
                            icon: Icons.stars_rounded,
                            label: 'Kỹ năng',
                            value: task.requiredSkill),
                      ],
                    ]),
              ),
              const SizedBox(height: 16),
              // Progress update card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cập nhật tiến độ',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 20),
                      // Circular progress
                      Center(
                          child: CircularPercentIndicator(
                        radius: 60,
                        lineWidth: 10,
                        percent: (_progress / 100).clamp(0.0, 1.0),
                        progressColor: AppColors.primaryBlue,
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.15),
                        center: Text('${_progress.toInt()}%',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryBlue)),
                      )),
                      const SizedBox(height: 20),
                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primaryBlue,
                          inactiveTrackColor:
                              AppColors.primaryBlue.withValues(alpha: 0.2),
                          thumbColor: Colors.white,
                          overlayColor:
                              AppColors.primaryBlue.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: _progress.clamp(0.0, 100.0),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${_progress.toInt()}%',
                          onChanged: (v) => setState(() {
                            _progress = v;
                            if (v == 100) {
                              _status = TaskStatus.done;
                            } else if (v > 0 && _status == TaskStatus.todo) {
                              _status = TaskStatus.inProgress;
                            } else if (v == 0) {
                              _status = TaskStatus.todo;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status / Workflow step selector
                      Row(
                        children: [
                          Text('Quy trình / Trạng thái',
                              style: Theme.of(context).textTheme.titleSmall),
                          if (task.statusName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.statusName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (task.workflowSteps.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: task.workflowSteps.map((step) {
                            final isSelected =
                                _selectedStepId == step.stepId;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedStepId = step.stepId;
                                final mapped = parseTaskStatus(step.label);
                                _status = mapped;
                                if (mapped == TaskStatus.done) {
                                  _progress = 100;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (step.isApprovalNode) ...[
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      step.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected ? Colors.white : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          children: TaskStatus.values
                              .where((s) => s != TaskStatus.cancelled)
                              .map((s) => GestureDetector(
                                    onTap: () => setState(() {
                                      _status = s;
                                      if (s == TaskStatus.done) {
                                        _progress = 100;
                                      } else if (s == TaskStatus.todo) {
                                        _progress = 0;
                                      }
                                    }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _status == s
                                            ? AppColors.primaryBlue
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _status == s
                                                ? AppColors.primaryBlue
                                                : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)),
                                      ),
                                      child: Text(s.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _status == s
                                                ? Colors.white
                                                : null,
                                          )),
                                    ),
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving
                              ? null
                              : () => _save(context, task),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Lưu thay đổi'),
                        ),
                      ),
                    ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon,
            size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ??
                        Theme.of(context).textTheme.bodyMedium?.color),
                overflow: TextOverflow.ellipsis)),
      ]);
}
