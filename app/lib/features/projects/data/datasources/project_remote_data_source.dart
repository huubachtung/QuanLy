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
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status);
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
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status) async {
    final Map<String, dynamic> data = {'progress': progress};
    if (status != null) {
      // Map TaskStatus enum to API string
      String statusStr;
      switch (status) {
        case TaskStatus.inProgress: statusStr = 'IN PROGRESS'; break;
        case TaskStatus.done: statusStr = 'FINISHED'; break;
        case TaskStatus.cancelled: statusStr = 'CANCELLED'; break;
        case TaskStatus.todo: statusStr = 'TODO'; break;
      }
      data['status'] = statusStr;
    }

    await apiClient.dio.put('${ApiConstants.tasks}/$taskId', data: data);
  }
}
