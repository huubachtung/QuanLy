import 'package:flutter/foundation.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

List<ProjectModel> _parseProjects(List<dynamic> jsonList) {
  return jsonList.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
}

List<TaskModel> _parseTasks(List<dynamic> jsonList) {
  return jsonList.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
}

List<ProjectScheduleModel> _parseSchedules(List<dynamic> jsonList) {
  return jsonList.map((e) => ProjectScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
}

abstract class ProjectRemoteDataSource {
  Future<Map<String, dynamic>> getProjectsData();
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status, {String? toStepId});
  Future<List<AvailableTransitionModel>> getAvailableTransitions(String taskId);
  Future<void> performWorkflowTransition(String taskId, String toStepId);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final ApiClient apiClient;

  ProjectRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getProjectsData() async {
    // Gọi tuần tự để giảm tải RAM trên thiết bị yếu
    final projectsResponse = await apiClient.dio.get(ApiConstants.projects);
    final projectsData = projectsResponse.data['data'] as List<dynamic>? 
        ?? projectsResponse.data as List<dynamic>? 
        ?? [];
    final projects = await compute(_parseProjects, projectsData);

    final tasksResponse = await apiClient.dio.get(ApiConstants.tasks);
    final tasksData = tasksResponse.data['data'] as List<dynamic>? 
        ?? tasksResponse.data as List<dynamic>? 
        ?? [];
    final tasks = await compute(_parseTasks, tasksData);

    List<ProjectScheduleModel> schedules = [];
    try {
      final schedulesResponse = await apiClient.dio.get(ApiConstants.projectSchedules);
      final schedulesData = schedulesResponse.data['data'] as List<dynamic>? 
          ?? schedulesResponse.data as List<dynamic>? 
          ?? [];
      schedules = await compute(_parseSchedules, schedulesData);
    } catch (_) {
      // Schedule là tùy chọn, không crash nếu lỗi
    }

    return {
      'projects': projects,
      'tasks': tasks,
      'schedules': schedules,
    };
  }

  @override
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status, {String? toStepId}) async {
    // 1. Cập nhật tiến độ task lên server (progress là integer 0-100)
    // Lưu ý: Không gửi status string ("IN PROGRESS", "TODO"...) vì status trong backend là ObjectId (ref: "Status")
    final Map<String, dynamic> data = {'progress': progress.round()};
    await apiClient.dio.put('${ApiConstants.tasks}/$taskId', data: data);

    // 2. Chuyển bước workflow nếu người dùng chọn bước mới
    if (toStepId != null && toStepId.isNotEmpty) {
      try {
        await apiClient.dio.post(ApiConstants.workflowTransition, data: {
          'scopeType': 'task',
          'scopeId': taskId,
          'toStepId': toStepId,
        });
      } catch (e) {
        debugPrint('Workflow transition failed: $e');
      }
    }
  }

  @override
  Future<List<AvailableTransitionModel>> getAvailableTransitions(String taskId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.availableTransitions('task', taskId),
      );
      final rawList = response.data is List
          ? response.data as List<dynamic>
          : (response.data is Map && response.data['data'] is List
              ? response.data['data'] as List<dynamic>
              : (response.data is Map && response.data['transitions'] is List
                  ? response.data['transitions'] as List<dynamic>
                  : []));

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => AvailableTransitionModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting available transitions: $e');
      return [];
    }
  }

  @override
  Future<void> performWorkflowTransition(String taskId, String toStepId) async {
    await apiClient.dio.post(ApiConstants.workflowTransition, data: {
      'scopeType': 'task',
      'scopeId': taskId,
      'toStepId': toStepId,
    });
  }
}
