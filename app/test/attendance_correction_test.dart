import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/requests/domain/entities/attendance_correction.dart';
import 'package:app/features/requests/data/models/attendance_correction_model.dart';
import 'package:app/features/requests/presentation/bloc/attendance_correction/attendance_correction_state.dart';

void main() {
  group('AttendanceCorrectionStatusExt Tests', () {
    test('fromString handles valid and fallback values', () {
      expect(AttendanceCorrectionStatusExt.fromString('PENDING'),
          AttendanceCorrectionStatus.pending);
      expect(AttendanceCorrectionStatusExt.fromString('approved'),
          AttendanceCorrectionStatus.approved);
      expect(AttendanceCorrectionStatusExt.fromString('REJECTED'),
          AttendanceCorrectionStatus.rejected);
      expect(AttendanceCorrectionStatusExt.fromString('CANCELLED'),
          AttendanceCorrectionStatus.cancelled);
      expect(AttendanceCorrectionStatusExt.fromString('UNKNOWN'),
          AttendanceCorrectionStatus.pending);
      expect(AttendanceCorrectionStatusExt.fromString(null),
          AttendanceCorrectionStatus.pending);
    });

    test('value and label extensions return expected strings', () {
      expect(AttendanceCorrectionStatus.pending.value, 'PENDING');
      expect(AttendanceCorrectionStatus.pending.label, 'Chờ duyệt');
      expect(AttendanceCorrectionStatus.approved.value, 'APPROVED');
      expect(AttendanceCorrectionStatus.approved.label, 'Đã duyệt');
      expect(AttendanceCorrectionStatus.rejected.value, 'REJECTED');
      expect(AttendanceCorrectionStatus.rejected.label, 'Từ chối');
      expect(AttendanceCorrectionStatus.cancelled.value, 'CANCELLED');
      expect(AttendanceCorrectionStatus.cancelled.label, 'Đã huỷ');
    });
  });

  group('AttendanceCorrectionModel Serialization Tests', () {
    test('fromJson parses server response accurately', () {
      final json = {
        '_id': '6aa3bea3fa8fff48092caf3e',
        'userId': '6a32b74f6c31356209a1dc1b',
        'date': '2026-09-11T00:00:00.000Z',
        'timeIn': '08:30',
        'timeOut': '18:00',
        'reason': 'Quên chấm công buổi sáng',
        'status': 'PENDING',
        'approver': {
          'displayName': 'Admin User',
        },
        'createdAt': '2026-09-11T08:41:07.342Z',
      };

      final model = AttendanceCorrectionModel.fromJson(json);

      expect(model.id, '6aa3bea3fa8fff48092caf3e');
      expect(model.userId, '6a32b74f6c31356209a1dc1b');
      expect(model.date, '2026-09-11');
      expect(model.timeIn, '08:30');
      expect(model.timeOut, '18:00');
      expect(model.reason, 'Quên chấm công buổi sáng');
      expect(model.status, AttendanceCorrectionStatus.pending);
      expect(model.approverName, 'Admin User');
    });

    test('toJson produces expected payload for POST', () {
      final model = AttendanceCorrectionModel(
        id: 'temp_id',
        userId: 'user_123',
        date: '2026-09-11',
        timeIn: '08:30',
        timeOut: '18:00',
        reason: 'Quên chấm công lúc về',
        status: AttendanceCorrectionStatus.pending,
        createdAt: DateTime.now(),
      );

      final json = model.toJson();

      expect(json['userId'], 'user_123');
      expect(json['date'], '2026-09-11');
      expect(json['timeIn'], '08:30');
      expect(json['timeOut'], '18:00');
      expect(json['reason'], 'Quên chấm công lúc về');
      expect(json.containsKey('id'), false);
    });
  });

  group('AttendanceCorrectionLoaded Filter Tests', () {
    final item1 = AttendanceCorrection(
      id: '1',
      userId: 'u1',
      date: '2026-09-10',
      reason: 'test 1',
      status: AttendanceCorrectionStatus.pending,
      createdAt: DateTime.now(),
    );
    final item2 = AttendanceCorrection(
      id: '2',
      userId: 'u1',
      date: '2026-09-11',
      reason: 'test 2',
      status: AttendanceCorrectionStatus.approved,
      createdAt: DateTime.now(),
    );
    final item3 = AttendanceCorrection(
      id: '3',
      userId: 'u1',
      date: '2026-09-12',
      reason: 'test 3',
      status: AttendanceCorrectionStatus.rejected,
      createdAt: DateTime.now(),
    );

    test('filteredRequests returns all when selectedStatus is ALL', () {
      final state = AttendanceCorrectionLoaded(
        requests: [item1, item2, item3],
        selectedMonth: 9,
        selectedYear: 2026,
        selectedStatus: 'ALL',
      );
      expect(state.filteredRequests.length, 3);
    });

    test('filteredRequests filters correctly for specific status', () {
      final statePending = AttendanceCorrectionLoaded(
        requests: [item1, item2, item3],
        selectedMonth: 9,
        selectedYear: 2026,
        selectedStatus: 'PENDING',
      );
      expect(statePending.filteredRequests.length, 1);
      expect(statePending.filteredRequests.first.id, '1');

      final stateApproved = AttendanceCorrectionLoaded(
        requests: [item1, item2, item3],
        selectedMonth: 9,
        selectedYear: 2026,
        selectedStatus: 'APPROVED',
      );
      expect(stateApproved.filteredRequests.length, 1);
      expect(stateApproved.filteredRequests.first.id, '2');
    });
  });
}
