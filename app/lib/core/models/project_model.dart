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

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      creatorId: (json['creator'] is Map ? json['creator']['_id'] : json['creator'])?.toString() ?? json['creatorId']?.toString() ?? '',
      leaderId: (json['leader'] is Map ? json['leader']['_id'] : json['leader'])?.toString() ?? json['leaderId']?.toString() ?? '',
      leaderName: (json['leader'] is Map ? json['leader']['displayName'] : json['leaderName'])?.toString() ?? '',
      supporterIds: (json['supporters'] as List<dynamic>?)?.map((e) => (e is Map ? e['_id'] : e).toString()).toList() ?? [],
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString())?.toLocal() ?? DateTime.now() : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString())?.toLocal() ?? DateTime.now() : DateTime.now(),
      status: _parseProjectStatus(json['status']?.toString()),
      progress: (json['progress'] ?? 0).toDouble(),
      tasks: (json['tasks'] as List<dynamic>?)?.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

ProjectStatus _parseProjectStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'IN PROGRESS':
      return ProjectStatus.inProgress;
    case 'FINISHED':
      return ProjectStatus.finished;
    case 'DELAYED':
      return ProjectStatus.delayed;
    case 'NOT STARTED':
    default:
      return ProjectStatus.notStarted;
  }
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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      projectId: (json['project'] is Map ? json['project']['_id'] : json['project'])?.toString() ?? json['projectId']?.toString() ?? '',
      projectName: (json['project'] is Map ? json['project']['name'] : json['projectName'])?.toString() ?? '',
      assignedToId: (json['assigned_to'] is Map ? json['assigned_to']['_id'] : json['assigned_to'])?.toString() ?? json['assignedToId']?.toString() ?? '',
      assignedToName: (json['assigned_to'] is Map ? json['assigned_to']['displayName'] : json['assignedToName'])?.toString() ?? '',
      reporterId: (json['reporter'] is Map ? json['reporter']['_id'] : json['reporter'])?.toString() ?? json['reporterId']?.toString() ?? '',
      reporterName: (json['reporter'] is Map ? json['reporter']['displayName'] : json['reporterName'])?.toString() ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
      status: _parseTaskStatus(json['status']?.toString()),
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString())?.toLocal() : null,
      deadlineDate: json['deadline_date'] != null ? DateTime.tryParse(json['deadline_date'].toString())?.toLocal() : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString())?.toLocal() : null,
      difficulty: json['difficulty'] != null ? int.tryParse(json['difficulty'].toString()) ?? 3 : 3,
      priority: json['priority']?.toString() ?? 'MEDIUM',
      requiredSkill: json['requiredSkill']?.toString() ?? '',
    );
  }
}

TaskStatus _parseTaskStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'IN_PROGRESS':
    case 'IN PROGRESS':
      return TaskStatus.inProgress;
    case 'DONE':
    case 'FINISHED':
      return TaskStatus.done;
    case 'CANCELLED':
      return TaskStatus.cancelled;
    case 'TODO':
    default:
      return TaskStatus.todo;
  }
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

  factory ProjectScheduleModel.fromJson(Map<String, dynamic> json) {
    return ProjectScheduleModel(
      id: json['_id'] ?? json['id'] ?? '',
      projectId: json['projectId'] ?? json['project']?['_id'] ?? '',
      projectName: json['projectName'] ?? json['project']?['name'] ?? '',
      projectDescription: json['projectDescription'] ?? json['project']?['description'] ?? '',
      projectStatus: _parseProjectStatus(json['projectStatus'] ?? json['project']?['status']),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : DateTime.now(),
    );
  }
}
