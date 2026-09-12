import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/attendance_correction_model.dart';

abstract class AttendanceCorrectionRemoteDataSource {
  Future<List<AttendanceCorrectionModel>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  });

  Future<AttendanceCorrectionModel> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  });

  Future<bool> deleteAttendanceCorrection(String id);
}

class AttendanceCorrectionRemoteDataSourceImpl
    implements AttendanceCorrectionRemoteDataSource {
  final ApiClient apiClient;

  AttendanceCorrectionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AttendanceCorrectionModel>> getAttendanceCorrections({
    int? month,
    int? year,
    String? status,
    String? userId,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams['status'] = status;
    }
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;

    final response = await apiClient.dio.get(
      ApiConstants.attendanceCorrection,
      queryParameters: queryParams,
    );

    dynamic rawList;
    if (response.data is List) {
      rawList = response.data;
    } else if (response.data is Map<String, dynamic>) {
      rawList = response.data['data'] ?? response.data['items'] ?? [];
    } else {
      rawList = [];
    }

    return (rawList as List)
        .map((item) =>
            AttendanceCorrectionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AttendanceCorrectionModel> createAttendanceCorrection({
    required String userId,
    required String date,
    required String? timeIn,
    required String? timeOut,
    required String reason,
  }) async {
    final Map<String, dynamic> body = {
      'userId': userId,
      'date': date,
      'reason': reason.trim(),
    };
    if (timeIn != null && timeIn.trim().isNotEmpty) {
      body['timeIn'] = timeIn.trim();
    }
    if (timeOut != null && timeOut.trim().isNotEmpty) {
      body['timeOut'] = timeOut.trim();
    }

    final response = await apiClient.dio.post(
      ApiConstants.attendanceCorrection,
      data: body,
    );

    Map<String, dynamic> dataMap;
    if (response.data is Map<String, dynamic>) {
      dataMap = (response.data['data'] is Map<String, dynamic>)
          ? response.data['data'] as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
    } else {
      throw Exception('Phản hồi từ máy chủ không hợp lệ');
    }

    return AttendanceCorrectionModel.fromJson(dataMap);
  }

  @override
  Future<bool> deleteAttendanceCorrection(String id) async {
    final response = await apiClient.dio.delete(
      '${ApiConstants.attendanceCorrection}/$id',
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
