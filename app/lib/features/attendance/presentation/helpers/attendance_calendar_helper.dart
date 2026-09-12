import '../../../../core/models/attendance_model.dart';

/// Helper to transform raw API attendance records into a complete Gregorian month calendar.
class AttendanceCalendarHelper {
  /// Robustly parses various date formats (ISO8601, YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY).
  static DateTime? parseRecordDate(String rawDate) {
    if (rawDate.isEmpty) return null;
    final tryIso = DateTime.tryParse(rawDate);
    if (tryIso != null) return tryIso.toLocal();

    final parts = rawDate.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        // YYYY-MM-DD
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      } else {
        // DD-MM-YYYY
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) return DateTime(y, m, d);
      }
    }
    return null;
  }

  /// Generates a full month of attendance records (1 to daysInMonth).
  ///
  /// For days with API data, the original record is preserved.
  /// For days without API data:
  /// - Weekends (Sat, Sun): status = off, note = ''
  /// - Future days: status = off, note = ''
  /// - Past weekdays: status = absent, note = ''
  static List<AttendanceModel> buildFullMonthRecords({
    required List<AttendanceModel> apiRecords,
    required int month,
    required int year,
    DateTime? referenceToday,
  }) {
    final now = referenceToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Index API records by day of month (1..31)
    final Map<int, AttendanceModel> recordsByDay = {};
    for (final record in apiRecords) {
      final parsed = parseRecordDate(record.date);
      if (parsed != null && parsed.month == month && parsed.year == year) {
        recordsByDay[parsed.day] = record;
      }
    }

    final List<AttendanceModel> fullList = [];

    for (int day = 1; day <= daysInMonth; day++) {
      if (recordsByDay.containsKey(day)) {
        fullList.add(recordsByDay[day]!);
      } else {
        final date = DateTime(year, month, day);
        final isFuture = date.isAfter(today);

        // Thứ 7, Chủ Nhật được xử lý đồng nhất như ngày bình thường:
        // - Ngày đã qua không có dữ liệu: absent (Vắng mặt)
        // - Ngày trong tương lai chưa diễn ra: off (Chưa tới)
        final AttendanceStatus status =
            isFuture ? AttendanceStatus.off : AttendanceStatus.absent;

        final formattedDate =
            '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        fullList.add(
          AttendanceModel(
            id: 'virtual_${year}_${month}_$day',
            userId: apiRecords.isNotEmpty ? apiRecords.first.userId : '',
            date: formattedDate,
            checkIn: null,
            checkOut: null,
            normalHours: 0,
            overtimeHours: 0,
            otStatus: OtStatus.none,
            dailyCong: 0,
            status: status,
            note: '',
            isLeave: false,
          ),
        );
      }
    }

    return fullList;
  }

  /// Returns short Vietnamese weekday abbreviation: T2, T3, T4, T5, T6, T7, CN.
  static String formatWeekdayShort(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }
}
