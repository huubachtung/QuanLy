import '../../../../core/models/attendance_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceModel>> getAttendanceData(int month, int year);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  @override
  Future<List<AttendanceModel>> getAttendanceData(int month, int year) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.generateAttendance(month, year);
  }
}
