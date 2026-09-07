import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/models/leave_request_model.dart';
import 'package:app/features/requests/presentation/pages/leave_request_page.dart';

void main() {
  group('Leave Quota Format & Business Logic Tests', () {
    test('LeaveType labels and deductsAnnualLeave match business specs', () {
      expect(LeaveType.annualLeave.label, 'Nghỉ phép năm');
      expect(LeaveType.annualLeave.deductsAnnualLeave, isTrue);

      expect(LeaveType.compensatoryLeave.label, 'Nghỉ bù');
      expect(LeaveType.compensatoryLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.sickLeave.label, 'Nghỉ ốm');
      expect(LeaveType.sickLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.summerLeave.label, 'Nghỉ hè');
      expect(LeaveType.summerLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.marriageLeave.label, 'Nghỉ kết hôn');
      expect(LeaveType.marriageLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.bereavementLeave.label, 'Nghỉ tang');
      expect(LeaveType.bereavementLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeBirthSingleNormal.label, 'Nghỉ vợ sinh thường (đơn)');
      expect(LeaveType.wifeBirthSingleNormal.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeBirthSingleSurgery.label, 'Nghỉ vợ sinh mổ (đơn)');
      expect(LeaveType.wifeBirthSingleSurgery.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeBirthTwinsNormal.label, 'Nghỉ vợ sinh thường (đôi)');
      expect(LeaveType.wifeBirthTwinsNormal.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeBirthTriplets.label, 'Nghỉ vợ sinh thường (ba)');
      expect(LeaveType.wifeBirthTriplets.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeBirthTwinsSurgery.label, 'Nghỉ vợ sinh mổ (đôi/ba)');
      expect(LeaveType.wifeBirthTwinsSurgery.deductsAnnualLeave, isFalse);

      expect(LeaveType.adoptionUnder6m.label, 'Nhận con nuôi dưới 6 tháng');
      expect(LeaveType.adoptionUnder6m.deductsAnnualLeave, isFalse);

      expect(LeaveType.contraceptionLeave.label, 'Nghỉ tránh thai');
      expect(LeaveType.contraceptionLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.recoveryLeave.label, 'Nghỉ phục hồi sức khoẻ');
      expect(LeaveType.recoveryLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.holidaysForExpats.label, 'Nghỉ lễ người nước ngoài');
      expect(LeaveType.holidaysForExpats.deductsAnnualLeave, isFalse);

      expect(LeaveType.militaryLeave.label, 'Nghỉ huấn luyện quân sự');
      expect(LeaveType.militaryLeave.deductsAnnualLeave, isFalse);

      expect(LeaveType.wifeMiscarriageOver22w.label, 'Nghỉ sẩy thai ≥22 tuần');
      expect(LeaveType.wifeMiscarriageOver22w.deductsAnnualLeave, isFalse);

      expect(LeaveType.unpaidLeave.label, 'Nghỉ không lương');
      expect(LeaveType.unpaidLeave.deductsAnnualLeave, isFalse);
    });

    test('LeaveStatItem calculates remaining properly for null or zero remaining', () {
      final expatLeave = LeaveStatItem.fromJson('HOLIDAYS_FOR_EXPATS', {
        'max': 0,
        'approved': 0,
        'pending': 0,
        'remaining': null,
        'deductsLeave': false,
        'label': 'Nghỉ lễ người nước ngoài',
      });
      expect(expatLeave.remaining, 0.0);

      final unpaidLeave = LeaveStatItem.fromJson('UNPAID_LEAVE', {
        'max': 30,
        'approved': 1,
        'pending': 0,
        'remaining': 29,
        'deductsLeave': false,
        'label': 'Nghỉ không lương',
      });
      expect(expatLeave.remaining, 0.0);
      expect(unpaidLeave.remaining, 29.0);
    });

    testWidgets('LeaveStatsTable renders 18 leave types with accurate format and badges',
        (tester) async {
      final testStats = [
        const LeaveStatItem(
          leaveType: 'ANNUAL_LEAVE',
          label: 'Nghỉ phép năm',
          deductsLeave: true,
          max: 12,
          approved: 0,
          pending: 0,
          remaining: 12,
        ),
        const LeaveStatItem(
          leaveType: 'COMPENSATORY_LEAVE',
          label: 'Nghỉ bù',
          deductsLeave: false,
          max: 12,
          approved: 0,
          pending: 0,
          remaining: 12,
        ),
        const LeaveStatItem(
          leaveType: 'SICK_LEAVE',
          label: 'Nghỉ ốm',
          deductsLeave: false,
          max: 12,
          approved: 0,
          pending: 0,
          remaining: 12,
        ),
        const LeaveStatItem(
          leaveType: 'SUMMER_LEAVE',
          label: 'Nghỉ hè',
          deductsLeave: false,
          max: 12,
          approved: 0,
          pending: 0,
          remaining: 12,
        ),
        const LeaveStatItem(
          leaveType: 'MARRIAGE_LEAVE',
          label: 'Nghỉ kết hôn',
          deductsLeave: false,
          max: 3,
          approved: 0,
          pending: 0,
          remaining: 3,
        ),
        const LeaveStatItem(
          leaveType: 'BEREAVEMENT_LEAVE',
          label: 'Nghỉ tang',
          deductsLeave: false,
          max: 3,
          approved: 0,
          pending: 0,
          remaining: 3,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_BIRTH_SINGLE_NORMAL',
          label: 'Nghỉ vợ sinh thường (đơn)',
          deductsLeave: false,
          max: 5,
          approved: 0,
          pending: 0,
          remaining: 5,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_BIRTH_SINGLE_SURGERY',
          label: 'Nghỉ vợ sinh mổ (đơn)',
          deductsLeave: false,
          max: 7,
          approved: 0,
          pending: 0,
          remaining: 7,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_BIRTH_TWINS_NORMAL',
          label: 'Nghỉ vợ sinh thường (đôi)',
          deductsLeave: false,
          max: 7,
          approved: 0,
          pending: 0,
          remaining: 7,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_BIRTH_TRIPLETS_NORMAL',
          label: 'Nghỉ vợ sinh thường (ba)',
          deductsLeave: false,
          max: 7,
          approved: 0,
          pending: 0,
          remaining: 7,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_BIRTH_TWINS_SURGERY',
          label: 'Nghỉ vợ sinh mổ (đôi/ba)',
          deductsLeave: false,
          max: 10,
          approved: 0,
          pending: 0,
          remaining: 10,
        ),
        const LeaveStatItem(
          leaveType: 'ADOPTION_UNDER_6M',
          label: 'Nhận con nuôi dưới 6 tháng',
          deductsLeave: false,
          max: 30,
          approved: 0,
          pending: 0,
          remaining: 30,
        ),
        const LeaveStatItem(
          leaveType: 'CONTRACEPTION_LEAVE',
          label: 'Nghỉ tránh thai',
          deductsLeave: false,
          max: 2,
          approved: 0,
          pending: 0,
          remaining: 2,
        ),
        const LeaveStatItem(
          leaveType: 'RECOVERY_LEAVE',
          label: 'Nghỉ phục hồi sức khoẻ',
          deductsLeave: false,
          max: 5,
          approved: 0,
          pending: 0,
          remaining: 5,
        ),
        const LeaveStatItem(
          leaveType: 'HOLIDAYS_FOR_EXPATS',
          label: 'Nghỉ lễ người nước ngoài',
          deductsLeave: false,
          max: 0,
          approved: 0,
          pending: 0,
          remaining: 0,
        ),
        const LeaveStatItem(
          leaveType: 'MILITARY_LEAVE',
          label: 'Nghỉ huấn luyện quân sự',
          deductsLeave: false,
          max: 0,
          approved: 0,
          pending: 0,
          remaining: 0,
        ),
        const LeaveStatItem(
          leaveType: 'WIFE_MISCARRIAGE_OVER_22W',
          label: 'Nghỉ sẩy thai ≥22 tuần',
          deductsLeave: false,
          max: 50,
          approved: 0,
          pending: 0,
          remaining: 50,
        ),
        const LeaveStatItem(
          leaveType: 'UNPAID_LEAVE',
          label: 'Nghỉ không lương',
          deductsLeave: false,
          max: 30,
          approved: 1,
          pending: 0,
          remaining: 29,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaveStatsTable(
                stats: testStats,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Headers
      expect(find.text('Loại đơn'), findsOneWidget);
      expect(find.text('Tổng'), findsOneWidget);
      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.text('Đang chờ'), findsOneWidget);
      expect(find.text('Còn lại'), findsOneWidget);

      // Subtitles
      expect(find.text('Trừ phép tháng'), findsOneWidget);
      expect(find.text('Không trừ phép tháng'), findsNWidgets(17));

      // Labels
      expect(find.text('Nghỉ phép năm'), findsOneWidget);
      expect(find.text('Nghỉ bù'), findsOneWidget);
      expect(find.text('Nghỉ ốm'), findsOneWidget);
      expect(find.text('Nghỉ hè'), findsOneWidget);
      expect(find.text('Nghỉ tránh thai'), findsOneWidget);
      expect(find.text('Nghỉ lễ người nước ngoài'), findsOneWidget);
      expect(find.text('Nghỉ huấn luyện quân sự'), findsOneWidget);
      expect(find.text('Nghỉ sẩy thai ≥22 tuần'), findsOneWidget);
      expect(find.text('Nghỉ không lương'), findsOneWidget);

      // Badges
      expect(find.text('Sắp hết'), findsOneWidget); // For Nghỉ tránh thai (remaining: 2)
      expect(find.text('Hết'), findsNWidgets(2)); // For Holidays & Military (remaining: 0)
    });
  });
}
