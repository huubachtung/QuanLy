import '../../../../core/models/overtime_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class OvertimeRemoteDataSource {
  Future<List<OvertimeModel>> getOvertimeData(int month, int year);
  Future<void> updateRecord(String id, double requestedHours, String reason);
  Future<void> markNoOt(String id);
}

class OvertimeRemoteDataSourceImpl implements OvertimeRemoteDataSource {
  List<OvertimeModel> _cache = [];

  @override
  Future<List<OvertimeModel>> getOvertimeData(int month, int year) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // If not matching, regenerate, otherwise keep cache to see updates
    // Simplification for Mock:
    _cache = MockData.generateOvertimeData(month, year);
    return _cache;
  }

  @override
  Future<void> updateRecord(String id, double requestedHours, String reason) async {
    final idx = _cache.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _cache[idx];
      _cache[idx] = OvertimeModel(
        id: old.id, userId: old.userId, date: old.date,
        systemOtHours: old.systemOtHours,
        requestedHours: requestedHours,
        reason: reason,
        status: requestedHours > 0 ? OtRequestStatus.pending : OtRequestStatus.noOt,
        checkIn: old.checkIn, checkOut: old.checkOut,
      );
    }
  }

  @override
  Future<void> markNoOt(String id) async {
    final idx = _cache.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _cache[idx];
      _cache[idx] = OvertimeModel(
        id: old.id, userId: old.userId, date: old.date,
        systemOtHours: old.systemOtHours, requestedHours: 0,
        reason: '', status: OtRequestStatus.noOt,
        checkIn: old.checkIn, checkOut: old.checkOut,
      );
    }
  }
}
