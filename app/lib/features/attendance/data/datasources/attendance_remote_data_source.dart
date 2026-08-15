import '../../../../core/models/attendance_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceResponseModel> getAttendanceData(int month, int year);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AttendanceResponseModel> getAttendanceData(int month, int year) async {
    final response = await apiClient.dio.get(
      ApiConstants.attendanceReport,
      queryParameters: {'month': month, 'year': year},
    );

    dynamic rawData = response.data;
    Map<String, dynamic> responseObj = {};

    if (rawData is Map) {
      if (rawData['data'] is List && (rawData['data'] as List).isNotEmpty) {
        responseObj = rawData['data'][0] as Map<String, dynamic>;
      } else if (rawData['data'] is Map) {
        responseObj = rawData['data'] as Map<String, dynamic>;
      } else {
        responseObj = rawData as Map<String, dynamic>;
      }
    } else if (rawData is List && rawData.isNotEmpty) {
      responseObj = rawData[0] as Map<String, dynamic>;
    }

    return AttendanceResponseModel.fromJson(responseObj);
  }
}
