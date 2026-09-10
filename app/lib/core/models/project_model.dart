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

ProjectStatus _parseProjectStatus(dynamic status) {
  String? statusStr;
  if (status is Map) {
    statusStr = status['name']?.toString() ??
        status['status']?.toString() ??
        status['label']?.toString();
  } else {
    statusStr = status?.toString();
  }
  final upper = statusStr?.toUpperCase() ?? '';
  if (upper.contains('IN PROGRESS') || upper.contains('IN_PROGRESS')) {
    return ProjectStatus.inProgress;
  }
  if (upper.contains('FINISHED') || upper.contains('DONE') || upper.contains('HOÀN THÀNH')) {
    return ProjectStatus.finished;
  }
  if (upper.contains('DELAYED') || upper.contains('TRỄ')) {
    return ProjectStatus.delayed;
  }
  return ProjectStatus.notStarted;
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

// ── Workflow Step Model ───────────────────────────────────────
class WorkflowStepModel {
  final String id;
  final String stepId;
  final String label;
  final String icon;
  final int order;
  final bool isApprovalNode;

  const WorkflowStepModel({
    required this.id,
    required this.stepId,
    required this.label,
    this.icon = '',
    this.order = 1,
    this.isApprovalNode = false,
  });

  factory WorkflowStepModel.fromJson(Map<String, dynamic> json) {
    return WorkflowStepModel(
      id: json['_id']?.toString() ?? '',
      stepId: json['stepId']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 1,
      isApprovalNode: json['isApprovalNode'] == true,
    );
  }
}

// ── Workflow Transition Model ─────────────────────────────────
class WorkflowTransitionModel {
  final String id;
  final String from;
  final String to;
  final String type; // NEXT, APPROVE, REJECT, CANCEL
  final String label;
  final List<String> allowedRoles;
  final bool requiresApproval;
  final String conditionNote;

  const WorkflowTransitionModel({
    this.id = '',
    required this.from,
    required this.to,
    this.type = 'NEXT',
    this.label = '',
    this.allowedRoles = const [],
    this.requiresApproval = false,
    this.conditionNote = '',
  });

  factory WorkflowTransitionModel.fromJson(Map<String, dynamic> json) {
    List<String> roles = [];
    if (json['allowedRoles'] is List) {
      roles = (json['allowedRoles'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return WorkflowTransitionModel(
      id: json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      type: (json['type']?.toString().toUpperCase()) ?? 'NEXT',
      label: json['label']?.toString() ?? '',
      allowedRoles: roles,
      requiresApproval: json['requiresApproval'] == true,
      conditionNote: json['conditionNote']?.toString() ?? '',
    );
  }
}

// ── Available Transition Model ─────────────────────────────────
class AvailableTransitionModel {
  final String toStepId;
  final String toStepLabel;
  final String type; // NEXT, APPROVE, REJECT, CANCEL
  final String label;
  final String fromStepId;
  final bool requiresApproval;
  final List<String> allowedRoles;

  const AvailableTransitionModel({
    required this.toStepId,
    this.toStepLabel = '',
    this.type = 'NEXT',
    this.label = '',
    this.fromStepId = '',
    this.requiresApproval = false,
    this.allowedRoles = const [],
  });

  factory AvailableTransitionModel.fromJson(Map<String, dynamic> json) {
    List<String> roles = [];
    if (json['allowedRoles'] is List) {
      roles = (json['allowedRoles'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return AvailableTransitionModel(
      toStepId: json['toStepId']?.toString() ??
          json['to']?.toString() ??
          json['targetStepId']?.toString() ??
          json['stepId']?.toString() ??
          '',
      toStepLabel: json['toStepLabel']?.toString() ??
          json['stepLabel']?.toString() ??
          json['label']?.toString() ??
          json['targetStep']?['label']?.toString() ??
          '',
      type: (json['type']?.toString().toUpperCase()) ?? 'NEXT',
      label: json['label']?.toString() ?? '',
      fromStepId: json['fromStepId']?.toString() ??
          json['from']?.toString() ??
          '',
      requiresApproval: json['requiresApproval'] == true,
      allowedRoles: roles,
    );
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
  final String statusId;
  final String statusName;
  final String currentStepId;
  final List<WorkflowStepModel> workflowSteps;
  final List<WorkflowTransitionModel> workflowTransitions;
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
    this.statusId = '',
    this.statusName = '',
    this.currentStepId = '',
    this.workflowSteps = const [],
    this.workflowTransitions = const [],
    this.startDate,
    this.deadlineDate,
    this.completedAt,
    this.difficulty = 3,
    this.priority = 'MEDIUM',
    this.requiredSkill = '',
  });

  TaskModel copyWith({
    String? id,
    String? name,
    String? description,
    String? projectId,
    String? projectName,
    String? assignedToId,
    String? assignedToName,
    String? reporterId,
    String? reporterName,
    double? progress,
    TaskStatus? status,
    String? statusId,
    String? statusName,
    String? currentStepId,
    List<WorkflowStepModel>? workflowSteps,
    List<WorkflowTransitionModel>? workflowTransitions,
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime? completedAt,
    int? difficulty,
    String? priority,
    String? requiredSkill,
  }) {
    return TaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      currentStepId: currentStepId ?? this.currentStepId,
      workflowSteps: workflowSteps ?? this.workflowSteps,
      workflowTransitions: workflowTransitions ?? this.workflowTransitions,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      completedAt: completedAt ?? this.completedAt,
      difficulty: difficulty ?? this.difficulty,
      priority: priority ?? this.priority,
      requiredSkill: requiredSkill ?? this.requiredSkill,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Parse status object or string
    String statusName = '';
    String statusId = '';
    if (json['status'] is Map) {
      statusName = json['status']['name']?.toString() ?? '';
      statusId = json['status']['_id']?.toString() ?? '';
    } else if (json['status'] is String) {
      statusName = json['status'] as String;
    }

    // Parse workflow template steps
    List<WorkflowStepModel> steps = [];
    List<WorkflowTransitionModel> transitions = [];
    if (json['workflow_template'] is Map) {
      final wfMap = json['workflow_template'] as Map<String, dynamic>;
      if (wfMap['steps'] is List) {
        final stepsRaw = wfMap['steps'] as List<dynamic>;
        steps = stepsRaw
            .whereType<Map<String, dynamic>>()
            .map((s) => WorkflowStepModel.fromJson(s))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
      if (wfMap['transitions'] is List) {
        final transRaw = wfMap['transitions'] as List<dynamic>;
        transitions = transRaw
            .whereType<Map<String, dynamic>>()
            .map((t) => WorkflowTransitionModel.fromJson(t))
            .toList();
      }
    }

    // Determine currentStepId
    String currentStep = '';
    if (steps.isNotEmpty) {
      final matching = steps.where(
          (s) => s.label == statusName || (statusId.isNotEmpty && s.id == statusId));
      if (matching.isNotEmpty) {
        currentStep = matching.first.stepId;
      } else {
        currentStep = steps.first.stepId;
      }
    }

    final parsedStatus = parseTaskStatus(statusName.isNotEmpty ? statusName : json['status']?.toString());

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
      status: parsedStatus,
      statusId: statusId,
      statusName: statusName.isNotEmpty ? statusName : parsedStatus.label,
      currentStepId: currentStep,
      workflowSteps: steps,
      workflowTransitions: transitions,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString())?.toLocal() : null,
      deadlineDate: json['deadline_date'] != null ? DateTime.tryParse(json['deadline_date'].toString())?.toLocal() : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString())?.toLocal() : null,
      difficulty: json['difficulty'] != null ? int.tryParse(json['difficulty'].toString()) ?? 3 : 3,
      priority: json['priority']?.toString() ?? 'MEDIUM',
      requiredSkill: json['requiredSkill']?.toString() ?? '',
    );
  }
}

TaskStatus parseTaskStatus(String? status) {
  if (status == null || status.isEmpty) return TaskStatus.todo;
  final upper = status.toUpperCase();
  if (upper.contains('DONE') ||
      upper.contains('FINISHED') ||
      upper.contains('MERGED') ||
      upper.contains('HOÀN THÀNH')) {
    return TaskStatus.done;
  }
  if (upper.contains('CANCEL') || upper.contains('HỦY')) {
    return TaskStatus.cancelled;
  }
  if (upper.contains('TEST') ||
      upper.contains('CODE') ||
      upper.contains('REVIEW') ||
      upper.contains('DOING') ||
      upper.contains('IN_PROGRESS') ||
      upper.contains('IN PROGRESS') ||
      upper.contains('ĐANG') ||
      upper.contains('TIẾN ĐỘ')) {
    return TaskStatus.inProgress;
  }
  return TaskStatus.todo;
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
