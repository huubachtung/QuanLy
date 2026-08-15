import '../../../../core/models/leave_request_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class LeaveRemoteDataSource {
  Future<List<LeaveRequestModel>> getLeaveRequests();
  Future<bool> createRequest(LeaveRequestModel request);
  Future<bool> cancelRequest(String id);
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final ApiClient apiClient;

  LeaveRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await apiClient.dio.get(ApiConstants.leaveRequests);
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => LeaveRequestModel.fromJson(e)).toList();
  }

  @override
  Future<bool> createRequest(LeaveRequestModel request) async {
    final response = await apiClient.dio.post(
      ApiConstants.leaveRequests,
      data: request.toJson(),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  @override
  Future<bool> cancelRequest(String id) async {
    final response = await apiClient.dio.delete('${ApiConstants.leaveRequests}/$id');
    return response.statusCode == 200;
  }
}
