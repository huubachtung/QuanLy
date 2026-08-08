import '../../../../core/models/project_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class ProjectRemoteDataSource {
  Future<Map<String, dynamic>> getProjectsData();
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getProjectsData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'projects': MockData.projects,
      'tasks': MockData.tasks,
      'schedules': MockData.projectSchedules,
    };
  }

  @override
  Future<void> updateTaskProgress(String taskId, double progress, TaskStatus? status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simulated remote update
  }
}
