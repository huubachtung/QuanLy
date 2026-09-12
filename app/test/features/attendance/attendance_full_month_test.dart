import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/models/attendance_model.dart';
import 'package:app/features/attendance/presentation/helpers/attendance_calendar_helper.dart';

void main() {
  group('AttendanceStatus.holiday Tests', () {
    test('AttendanceStatus.holiday returns expected label', () {
      expect(AttendanceStatus.holiday.label, 'Nghỉ lễ (Hưởng lương)');
    });

    test('AttendanceModel.fromJson parses HOLIDAY status correctly', () {
      final json = {
        'id': 'h1',
        'userId': 'u1',
        'date': '2026-09-01',
        'status': 'HOLIDAY',
        'dailyCong': 1.0,
        'note': 'Nghỉ lễ Quốc khánh',
      };
      final model = AttendanceModel.fromJson(json);
      expect(model.status, AttendanceStatus.holiday);
      expect(model.dailyCong, 1.0);
      expect(model.note, 'Nghỉ lễ Quốc khánh');
    });

    test('AttendanceModel.fromJson recognizes note containing Nghỉ lễ', () {
      final json = {
        'id': 'h2',
        'userId': 'u1',
        'date': '2026-09-02',
        'status': 'DONE',
        'dailyCong': 1.0,
        'note': 'Nghỉ lễ (Hưởng lương)',
      };
      final model = AttendanceModel.fromJson(json);
      expect(model.status, AttendanceStatus.holiday);
    });
  });

  group('AttendanceCalendarHelper.parseRecordDate', () {
    test('parses ISO8601 string correctly', () {
      final date =
          AttendanceCalendarHelper.parseRecordDate('2026-09-11T00:00:00.000Z');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 11);
    });

    test('parses YYYY-MM-DD correctly', () {
      final date = AttendanceCalendarHelper.parseRecordDate('2026-09-01');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 1);
    });

    test('parses DD/MM/YYYY correctly', () {
      final date = AttendanceCalendarHelper.parseRecordDate('15/09/2026');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 15);
    });

    test('parses DD-MM-YYYY correctly', () {
      final date = AttendanceCalendarHelper.parseRecordDate('30-09-2026');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 9);
      expect(date.day, 30);
    });

    test('returns null for empty or invalid format', () {
      expect(AttendanceCalendarHelper.parseRecordDate(''), isNull);
      expect(AttendanceCalendarHelper.parseRecordDate('invalid_date'), isNull);
    });
  });

  group('AttendanceCalendarHelper.formatWeekdayShort', () {
    test('returns correct Vietnamese weekday abbreviations', () {
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 7)),
          'T2');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 8)),
          'T3');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 9)),
          'T4');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 10)),
          'T5');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 11)),
          'T6');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 12)),
          'T7');
      expect(
          AttendanceCalendarHelper.formatWeekdayShort(DateTime(2026, 9, 13)),
          'CN');
    });
  });

  group('AttendanceCalendarHelper.buildFullMonthRecords', () {
    test('generates correct number of days for different months', () {
      final feb2024 = AttendanceCalendarHelper.buildFullMonthRecords(
        apiRecords: [],
        month: 2,
        year: 2024,
      );
      expect(feb2024.length, 29);

      final feb2025 = AttendanceCalendarHelper.buildFullMonthRecords(
        apiRecords: [],
        month: 2,
        year: 2025,
      );
      expect(feb2025.length, 28);

      final sep2026 = AttendanceCalendarHelper.buildFullMonthRecords(
        apiRecords: [],
        month: 9,
        year: 2026,
      );
      expect(sep2026.length, 30);

      final jul2026 = AttendanceCalendarHelper.buildFullMonthRecords(
        apiRecords: [],
        month: 7,
        year: 2026,
      );
      expect(jul2026.length, 31);
    });

    test('preserves server records, handles holiday, and treats weekends as regular days', () {
      // Reference date: 2026-09-12 (Saturday)
      final refDate = DateTime(2026, 9, 12);

      // Server holiday records for 01/09 and 02/09
      const holidayRecord1 = AttendanceModel(
        id: 'hol_1',
        userId: 'u123',
        date: '2026-09-01',
        dailyCong: 1.0,
        status: AttendanceStatus.holiday,
        note: 'Nghỉ lễ (Hưởng lương)',
      );

      const holidayRecord2 = AttendanceModel(
        id: 'hol_2',
        userId: 'u123',
        date: '2026-09-02',
        dailyCong: 1.0,
        status: AttendanceStatus.holiday,
        note: 'Nghỉ lễ Quốc Khánh',
      );

      final workRecord = AttendanceModel(
        id: 'work_3',
        userId: 'u123',
        date: '2026-09-03',
        checkIn: DateTime(2026, 9, 3, 8, 25),
        checkOut: DateTime(2026, 9, 3, 17, 35),
        normalHours: 8.0,
        dailyCong: 1.0,
        status: AttendanceStatus.done,
        note: 'Đi làm đúng giờ',
      );

      final fullRecords = AttendanceCalendarHelper.buildFullMonthRecords(
        apiRecords: [holidayRecord1, holidayRecord2, workRecord],
        month: 9,
        year: 2026,
        referenceToday: refDate,
      );

      expect(fullRecords.length, 30);

      // Day 1: 01/09 -> Holiday
      final day1 = fullRecords[0];
      expect(day1.status, AttendanceStatus.holiday);
      expect(day1.note, 'Nghỉ lễ (Hưởng lương)');
      expect(day1.dailyCong, 1.0);

      // Day 2: 02/09 -> Holiday
      final day2 = fullRecords[1];
      expect(day2.status, AttendanceStatus.holiday);
      expect(day2.note, 'Nghỉ lễ Quốc Khánh');
      expect(day2.dailyCong, 1.0);

      // Day 3: 03/09 -> Server work record
      final day3 = fullRecords[2];
      expect(day3.status, AttendanceStatus.done);
      expect(day3.dailyCong, 1.0);

      // Day 4: 2026-09-04 (Friday, past weekday without record) -> absent
      final day4 = fullRecords[3];
      expect(day4.status, AttendanceStatus.absent);
      expect(day4.note, isEmpty);

      // Day 6: 2026-09-06 (Sunday, past weekend without record) -> absent (regular day behavior)
      final day6 = fullRecords[5];
      expect(day6.status, AttendanceStatus.absent);
      expect(day6.note, isEmpty);

      // Day 20: 2026-09-20 (Sunday, future date after refDate) -> off (chưa tới)
      final day20 = fullRecords[19];
      expect(day20.status, AttendanceStatus.off);
      expect(day20.note, isEmpty);

      // Day 21: 2026-09-21 (Monday, future date after refDate) -> off (chưa tới)
      final day21 = fullRecords[20];
      expect(day21.status, AttendanceStatus.off);
      expect(day21.note, isEmpty);
    });
  });
}
