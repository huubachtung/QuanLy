import '../../../../core/models/leave_request_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class LeaveRemoteDataSource {
  Future<LeaveDataResponse> getLeaveRequests();
  Future<bool> createRequest(LeaveRequestModel request);
  Future<bool> cancelRequest(String id);
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final ApiClient apiClient;

  LeaveRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LeaveDataResponse> getLeaveRequests() async {
    final response = await apiClient.dio.get(ApiConstants.leaveRequests);
    if (response.data is Map<String, dynamic>) {
      return LeaveDataResponse.fromJson(response.data as Map<String, dynamic>);
    }
    return const LeaveDataResponse(requests: []);
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
