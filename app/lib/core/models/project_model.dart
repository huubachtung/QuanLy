// ── Project Model ─────────────────────────────────────────────
class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String leaderId;
  final String leaderName;
  final List<String> supporterIds;
  final DateTime startDate;
  final DateTime endDate;
  final ProjectStatus status;
  final double progress;
  final List<TaskModel> tasks;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.leaderId,
    required this.leaderName,
    this.supporterIds = const [],
    required this.startDate,
    required this.endDate,
    required this.status,
    this.progress = 0,
    this.tasks = const [],
  });
}

enum ProjectStatus { notStarted, inProgress, finished, delayed }

extension ProjectStatusExt on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.notStarted: return 'Chưa bắt đầu';
      case ProjectStatus.inProgress: return 'Đang thực hiện';
      case ProjectStatus.finished: return 'Hoàn thành';
      case ProjectStatus.delayed: return 'Trễ hạn';
    }
  }
}

// ── Task Model ────────────────────────────────────────────────
class TaskModel {
  final String id;
  final String name;
  final String description;
  final String projectId;
  final String projectName;
  final String assignedToId;
  final String assignedToName;
  final String reporterId;
  final String reporterName;
  final double progress;
  final TaskStatus status;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final DateTime? completedAt;
  final int difficulty; // 1-5
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String requiredSkill;

  const TaskModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.projectId,
    required this.projectName,
    required this.assignedToId,
    required this.assignedToName,
    required this.reporterId,
    required this.reporterName,
    this.progress = 0,
    required this.status,
    this.startDate,
    this.deadlineDate,
    this.completedAt,
    this.difficulty = 3,
    this.priority = 'MEDIUM',
    this.requiredSkill = '',
  });
}

enum TaskStatus { todo, inProgress, done, cancelled }

extension TaskStatusExt on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo: return 'Chưa làm';
      case TaskStatus.inProgress: return 'Đang làm';
      case TaskStatus.done: return 'Hoàn thành';
      case TaskStatus.cancelled: return 'Đã huỷ';
    }
  }
}

// ── Project Schedule (Calendar) ────────────────────────────────
class ProjectScheduleModel {
  final String id;
  final String projectId;
  final String projectName;
  final String projectDescription;
  final ProjectStatus projectStatus;
  final DateTime scheduledDate;

  const ProjectScheduleModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectDescription,
    required this.projectStatus,
    required this.scheduledDate,
  });
}
