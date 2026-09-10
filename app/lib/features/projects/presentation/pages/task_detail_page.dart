import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';
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
  bool _savingProgress = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(LoadAvailableTransitions(widget.taskId));
    });
  }

  void _saveProgress(BuildContext context, TaskModel task) {
    if (_savingProgress) return;
    setState(() => _savingProgress = true);

    context.read<ProjectsBloc>().add(UpdateTaskProgressEvent(
          taskId: widget.taskId,
          progress: _progress,
          status: _status,
        ));
  }

  void _confirmAndTransition(
    BuildContext context,
    TaskModel task,
    AvailableTransitionModel transition,
    String actionLabel,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận chuyển bước'),
        content: Text(
          'Bạn có chắc chắn muốn thực hiện hành động:\n"$actionLabel"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<ProjectsBloc>().add(PerformWorkflowTransitionEvent(
                    taskId: task.id,
                    toStepId: transition.toStepId,
                  ));
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (_savingProgress) {
          if (state is ProjectsLoaded) {
            setState(() => _savingProgress = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Cập nhật tiến độ thành công'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ));
          } else if (state is ProjectsError) {
            setState(() => _savingProgress = false);
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final taskIndex = state.tasks.indexWhere((t) => t.id == widget.taskId);
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Header Info Card
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          StatusBadge(
                            label: priorityLabel,
                            color: priorityColor,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s8),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: AppTokens.s16),
                      _InfoRow(
                        icon: Icons.folder_outlined,
                        label: 'Dự án',
                        value: task.projectName,
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _InfoRow(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Trạng thái',
                        value: task.statusName.isNotEmpty
                            ? task.statusName
                            : task.status.label,
                        valueColor: isDark
                            ? AppColors.primaryLight
                            : AppColors.primaryBlue,
                      ),
                      const SizedBox(height: AppTokens.s8),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Người giao',
                        value: task.reporterName,
                      ),
                      if (task.assignedToName.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s8),
                        _InfoRow(
                          icon: Icons.person_pin_circle_outlined,
                          label: 'Người thực hiện',
                          value: task.assignedToName,
                        ),
                      ],
                      if (task.deadlineDate != null) ...[
                        const SizedBox(height: AppTokens.s8),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Deadline',
                          value: DateFormat('dd/MM/yyyy').format(task.deadlineDate!),
                          valueColor: task.deadlineDate!.isBefore(DateTime.now()) &&
                                  task.status != TaskStatus.done
                              ? AppColors.error
                              : null,
                        ),
                      ],
                      if (task.requiredSkill.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s8),
                        _InfoRow(
                          icon: Icons.stars_rounded,
                          label: 'Kỹ năng',
                          value: task.requiredSkill,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s16),

                // 2. Workflow Pipeline Stepper & Actions Card
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timeline_rounded,
                            size: 20,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppTokens.s8),
                          Text(
                            'Tiến trình giai đoạn',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.s4),
                      Text(
                        'Quy trình làm việc tuần tự theo từng giai đoạn',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),

                      // Stepper track
                      if (task.workflowSteps.isNotEmpty) ...[
                        _WorkflowStepper(
                          steps: task.workflowSteps,
                          currentStepId: task.currentStepId,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Divider(
                          height: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        const SizedBox(height: AppTokens.s16),
                        Text(
                          'Hành động chuyển bước',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppTokens.s12),
                        _buildWorkflowActions(context, task, state, isDark),
                      ] else ...[
                        // Fallback static status selector when no workflow attached
                        Text(
                          'Chọn trạng thái công việc:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppTokens.s12),
                        Wrap(
                          spacing: AppTokens.s8,
                          children: TaskStatus.values
                              .where((s) => s != TaskStatus.cancelled)
                              .map((s) {
                            final isSel = _status == s;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _status = s;
                                if (s == TaskStatus.done) {
                                  _progress = 100;
                                } else if (s == TaskStatus.todo) {
                                  _progress = 0;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: AppTokens.animFast,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.s12,
                                  vertical: AppTokens.s8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? (isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primaryBlue)
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.rMicro),
                                  border: Border.all(
                                    color: isSel
                                        ? (isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primaryBlue)
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                  ),
                                ),
                                child: Text(
                                  s.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSel ? Colors.white : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s16),

                // 3. Progress Card (% Slider)
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppTokens.rCard),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiến độ công việc',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      Center(
                        child: CircularPercentIndicator(
                          radius: 52,
                          lineWidth: 8,
                          percent: (_progress / 100).clamp(0.0, 1.0),
                          progressColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primaryBlue,
                          backgroundColor: (isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primaryBlue)
                              .withValues(alpha: 0.15),
                          center: Text(
                            '${_progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primaryBlue,
                          inactiveTrackColor: (isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primaryBlue)
                              .withValues(alpha: 0.2),
                          thumbColor: Colors.white,
                          overlayColor: (isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primaryBlue)
                              .withValues(alpha: 0.15),
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
                      const SizedBox(height: AppTokens.s16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savingProgress ? null : () => _saveProgress(context, task),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppTokens.s12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTokens.rInput),
                            ),
                          ),
                          child: _savingProgress
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Lưu tiến độ (%)'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkflowActions(
    BuildContext context,
    TaskModel task,
    ProjectsLoaded state,
    bool isDark,
  ) {
    final transitions = state.transitionsForTask(task.id);
    final isTransitioning = state.isTransitioning;

    if (isTransitioning) {
      return Container(
        padding: const EdgeInsets.all(AppTokens.s16),
        alignment: Alignment.center,
        child: const Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: AppTokens.s8),
            Text(
              'Đang xử lý chuyển bước...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    if (transitions.isEmpty) {
      if (task.status == TaskStatus.done) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              SizedBox(width: AppTokens.s8),
              Text(
                'Công việc đã hoàn thành',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      final currentSteps = task.workflowSteps.where(
        (s) => s.stepId == task.currentStepId,
      );
      final currentStep = currentSteps.isNotEmpty ? currentSteps.first : null;

      if (currentStep != null && currentStep.isApprovalNode) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: AppTokens.s8),
              Text(
                'Đang chờ phê duyệt từ Leader / Quản lý',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s16,
          vertical: AppTokens.s12,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTokens.rInput),
        ),
        child: Text(
          'Không có thao tác chuyển bước nào khả dụng',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      );
    }

    return Column(
      children: transitions.map((transition) {
        final isApprove = transition.type == 'APPROVE';
        final isReject = transition.type == 'REJECT';
        final isCancel = transition.type == 'CANCEL';

        final actionLabel = transition.label.isNotEmpty
            ? transition.label
            : (transition.toStepLabel.isNotEmpty
                ? transition.toStepLabel
                : transition.toStepId);

        String buttonText;
        IconData buttonIcon;
        Color buttonColor;
        bool isOutlined = false;

        if (isApprove) {
          buttonText = 'Phê duyệt: $actionLabel';
          buttonIcon = Icons.check_circle_outline_rounded;
          buttonColor = AppColors.success;
        } else if (isReject) {
          buttonText = 'Từ chối: $actionLabel';
          buttonIcon = Icons.reply_rounded;
          buttonColor = AppColors.error;
          isOutlined = true;
        } else if (isCancel) {
          buttonText = 'Hủy: $actionLabel';
          buttonIcon = Icons.cancel_outlined;
          buttonColor = Colors.grey;
          isOutlined = true;
        } else {
          buttonText = 'Chuyển sang: $actionLabel';
          buttonIcon = Icons.arrow_forward_rounded;
          buttonColor = isDark ? AppColors.primaryLight : AppColors.primaryBlue;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s8),
          child: SizedBox(
            width: double.infinity,
            child: isOutlined
                ? OutlinedButton.icon(
                    onPressed: () => _confirmAndTransition(
                        context, task, transition, buttonText),
                    icon: Icon(buttonIcon, size: 18, color: buttonColor),
                    label: Text(buttonText),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonColor,
                      side: BorderSide(color: buttonColor.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s12,
                        horizontal: AppTokens.s16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.rInput),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _confirmAndTransition(
                        context, task, transition, buttonText),
                    icon: Icon(buttonIcon, size: 18, color: Colors.white),
                    label: Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.s12,
                        horizontal: AppTokens.s16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.rInput),
                      ),
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _WorkflowStepper extends StatelessWidget {
  final List<WorkflowStepModel> steps;
  final String currentStepId;
  final bool isDark;

  const _WorkflowStepper({
    required this.steps,
    required this.currentStepId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final currentIndex = steps.indexWhere((s) => s.stepId == currentStepId);
    final effectiveCurrentIdx = currentIndex != -1 ? currentIndex : 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (idx) {
          final step = steps[idx];
          final isCompleted = idx < effectiveCurrentIdx;
          final isCurrent = idx == effectiveCurrentIdx;

          final nodeColor = isCompleted
              ? AppColors.success
              : (isCurrent
                  ? (isDark ? AppColors.primaryLight : AppColors.primaryBlue)
                  : (isDark ? Colors.white24 : Colors.grey.shade400));

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step circle
                  Container(
                    width: isCurrent ? 36 : 28,
                    height: isCurrent ? 36 : 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : (isCurrent
                              ? (isDark
                                  ? AppColors.primaryLight.withValues(alpha: 0.18)
                                  : AppColors.primaryBlue.withValues(alpha: 0.12))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: nodeColor,
                        width: isCurrent ? 2.5 : 1.5,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: (isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryBlue)
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : (isCurrent
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : (step.isApprovalNode
                                  ? Icon(Icons.verified_user_outlined,
                                      size: 14, color: nodeColor)
                                  : Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: nodeColor,
                                      ),
                                    ))),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  // Step Label
                  SizedBox(
                    width: 88,
                    child: Column(
                      children: [
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : (isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.w400),
                            color: isCurrent
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryBlue)
                                : (isCompleted
                                    ? (isDark
                                        ? Colors.white
                                        : Colors.grey.shade800)
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.grey.shade500)),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryBlue)
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rMicro),
                            ),
                            child: const Text(
                              'Đang làm',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                        if (step.isApprovalNode && !isCurrent) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 10,
                                  color: isCompleted
                                      ? AppColors.success
                                      : AppColors.warning),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  'Cần duyệt',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Connecting line to next step
              if (idx < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Container(
                    width: 36,
                    height: 2.5,
                    color: isCompleted
                        ? AppColors.success
                        : (isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(
          icon,
          size: AppTokens.iconMicro,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: AppTokens.s8),
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]);
}
