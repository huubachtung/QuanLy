import '../../../../core/models/overtime_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class OvertimeRemoteDataSource {
  Future<List<OvertimeModel>> getOvertimeData(int month, int year);
  Future<void> updateRecord(String date, double requestedHours, String reason);
  Future<void> markNoOt(String date);
  Future<String> submitBulk(List<Map<String, dynamic>> entries);
  Future<void> deleteRecord(String id);
}

class OvertimeRemoteDataSourceImpl implements OvertimeRemoteDataSource {
  final ApiClient apiClient;

  OvertimeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OvertimeModel>> getOvertimeData(int month, int year) async {
    final response = await apiClient.dio.get(
      ApiConstants.overtimeMonthlySheet,
      queryParameters: {'month': month, 'year': year},
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => OvertimeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> updateRecord(String date, double requestedHours, String reason) async {
    await apiClient.dio.post(
      ApiConstants.overtimeRequests,
      data: {
        'date': date,
        'hours': requestedHours,
        'reason': reason.trim().isNotEmpty ? reason.trim() : (requestedHours == 0 ? 'Không OT' : ''),
      },
    );
  }

  @override
  Future<void> markNoOt(String date) async {
    await apiClient.dio.post(
      ApiConstants.overtimeRequests,
      data: {
        'date': date,
        'hours': 0,
        'reason': 'Không OT',
      },
    );
  }

  @override
  Future<String> submitBulk(List<Map<String, dynamic>> entries) async {
    final response = await apiClient.dio.post(
      ApiConstants.overtimeBulk,
      data: {
        'entries': entries,
      },
    );
    return response.data['message']?.toString() ?? 'Đã gửi duyệt bảng OT thành công';
  }

  @override
  Future<void> deleteRecord(String id) async {
    await apiClient.dio.delete('${ApiConstants.overtimeRequests}/$id');
  }
}
