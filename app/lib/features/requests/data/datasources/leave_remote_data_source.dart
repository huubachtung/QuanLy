import '../../../../core/models/leave_request_model.dart';
import '../../../../core/mock/mock_data.dart';

abstract class LeaveRemoteDataSource {
  Future<List<LeaveRequestModel>> getLeaveRequests();
  Future<bool> createRequest(LeaveRequestModel request);
  Future<bool> cancelRequest(String id);
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final List<LeaveRequestModel> _cache = List.from(MockData.leaveRequests)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _cache;
  }

  @override
  Future<bool> createRequest(LeaveRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _cache.insert(0, request);
    return true;
  }

  @override
  Future<bool> cancelRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _cache.indexWhere((r) => r.id == id);
    if (idx == -1) return false;
    final old = _cache[idx];
    if (old.status != RequestStatus.pending) return false;
    _cache[idx] = LeaveRequestModel(
      id: old.id, userId: old.userId, employeeCode: old.employeeCode,
      fromDate: old.fromDate, toDate: old.toDate, totalDays: old.totalDays,
      leaveType: old.leaveType, leaveDuration: old.leaveDuration,
      startTime: old.startTime, endTime: old.endTime,
      reason: old.reason, status: RequestStatus.cancelled,
      createdAt: old.createdAt,
    );
    return true;
  }
}
