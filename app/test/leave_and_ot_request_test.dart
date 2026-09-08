import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/models/leave_request_model.dart';
import 'package:app/core/models/overtime_model.dart';

void main() {
  group('LeaveRequestModel Serialization & Parsing Tests', () {
    test('Populated approverId is parsed into approverId and approverName', () {
      final json = {
        '_id': 'req_test_id_001',
        'userId': {
          '_id': 'user_test_id_001',
          'displayName': 'Nguyen Van Test',
          'employeeCode': 'EMP001'
        },
        'employeeCode': 'EMP001',
        'fromDate': '2026-09-03',
        'toDate': '2026-09-03',
        'totalDays': 1,
        'leaveType': 'LATE_PERMISSION',
        'leaveDuration': 'FULL_DAY',
        'startTime': '09:30',
        'reason': 'Xin di muon co viec rieng',
        'status': 'APPROVED',
        'approverId': {
          '_id': 'approver_test_id_001',
          'displayName': 'Nguoi Duyet Test'
        },
        'deductedLeave': 0,
      };

      final model = LeaveRequestModel.fromJson(json);

      expect(model.id, 'req_test_id_001');
      expect(model.userId, 'user_test_id_001');
      expect(model.employeeCode, 'EMP001');
      expect(model.leaveType, LeaveType.latePermission);
      expect(model.startTime, '09:30');
      expect(model.approverId, 'approver_test_id_001');
      expect(model.approverName, 'Nguoi Duyet Test');
      expect(model.status, RequestStatus.approved);
    });

    test('shiftChangeDate is parsed from json and serialized to json', () {
      final json = {
        '_id': 'req_test_id_002',
        'userId': 'user_test_id_001',
        'employeeCode': 'EMP001',
        'fromDate': '2026-09-12',
        'toDate': '2026-09-12',
        'shiftChangeDate': '2026-09-10',
        'totalDays': 0,
        'leaveType': 'SHIFT_CHANGE',
        'leaveDuration': 'FULL_DAY',
        'startTime': '08:30',
        'endTime': '17:30',
        'reason': 'Doi ca lam bu',
        'status': 'PENDING',
      };

      final model = LeaveRequestModel.fromJson(json);
      expect(model.shiftChangeDate, '2026-09-10');
      expect(model.startTime, '08:30');
      expect(model.endTime, '17:30');

      final serialized = model.toJson();
      expect(serialized['shiftChangeDate'], '2026-09-10');
      expect(serialized['fromDate'], '2026-09-12');
      expect(serialized['toDate'], '2026-09-12');
      expect(serialized['startTime'], '08:30');
      expect(serialized['endTime'], '17:30');
      expect(serialized['leaveType'], 'SHIFT_CHANGE');
    });

    test('LeaveType categorization: isSingleDayOnly vs isSpecialRequest', () {
      // onlineWork is special but NOT single day only
      expect(LeaveType.onlineWork.isSpecialRequest, true);
      expect(LeaveType.onlineWork.isSingleDayOnly, false);
      expect(LeaveType.onlineWork.isTimeBasedRequest, false);

      // latePermission and earlyLeaveRequest are single day only and time based
      expect(LeaveType.latePermission.isSingleDayOnly, true);
      expect(LeaveType.latePermission.isTimeBasedRequest, true);
      expect(LeaveType.earlyLeaveRequest.isSingleDayOnly, true);
      expect(LeaveType.earlyLeaveRequest.isTimeBasedRequest, true);

      // shiftChange is time based
      expect(LeaveType.shiftChange.isTimeBasedRequest, true);
      expect(LeaveType.shiftChange.isSingleDayOnly, false);

      // standard leave types
      expect(LeaveType.annualLeave.isSingleDayOnly, false);
      expect(LeaveType.annualLeave.isTimeBasedRequest, false);
    });
  });

  group('OvertimeModel Serialization Tests', () {
    test('OvertimeModel parses id and formats time correctly', () {
      final json = {
        'id': 'ot_test_id_001',
        'date': '2026-09-04',
        'calculatedOtHours': 3.06,
        'requestedOtHours': 3.06,
        'reason': 'Lam them gio',
        'status': 'PENDING',
        'approverId': {
          'displayName': 'Nguoi Duyet Test',
        },
      };

      final model = OvertimeModel.fromJson(json);
      expect(model.id, 'ot_test_id_001');
      expect(model.requestedOtHours, 3.06);
      expect(model.approverName, 'Nguoi Duyet Test');
      expect(model.status, OtStatus.pending);

      final singleJson = model.toSingleJson();
      expect(singleJson['date'], '2026-09-04');
      expect(singleJson['hours'], 3.06);
      expect(singleJson['reason'], 'Lam them gio');
    });
  });
}
