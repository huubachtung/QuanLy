import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/vietnamese_to_telex_formatter.dart';
import 'package:flutter/services.dart';

void main() {
  group('vietnameseToTelex tests', () {
    test('converts "tùng" to "tungf" as specified in user request', () {
      expect(vietnameseToTelex('tùng'), equals('tungf'));
    });

    test('converts username with numbers "tùng123" to "tungf123"', () {
      expect(vietnameseToTelex('tùng123'), equals('tungf123'));
    });

    test('converts various Vietnamese syllables', () {
      expect(vietnameseToTelex('toán'), equals('toans'));
      expect(vietnameseToTelex('đạt'), equals('ddatj'));
      expect(vietnameseToTelex('việt'), equals('vieetj'));
      expect(vietnameseToTelex('nguyễn'), equals('nguyeenx'));
      expect(vietnameseToTelex('thắng'), equals('thawngs'));
      expect(vietnameseToTelex('cường'), equals('cuowngf'));
      expect(vietnameseToTelex('hải'), equals('hair'));
      expect(vietnameseToTelex('dũng'), equals('dungx'));
      expect(vietnameseToTelex('tiến'), equals('tieens'));
      expect(vietnameseToTelex('tù'), equals('tuf'));
    });

    test('keeps plain English words and special characters intact', () {
      expect(vietnameseToTelex('tung'), equals('tung'));
      expect(vietnameseToTelex('tungf'), equals('tungf'));
      expect(vietnameseToTelex('admin'), equals('admin'));
      expect(vietnameseToTelex('user@domain.com'), equals('user@domain.com'));
      expect(vietnameseToTelex('Pass:123@>'), equals('Pass:123@>'));
    });

    test('handles uppercase words properly', () {
      expect(vietnameseToTelex('TÙNG'), equals('TUNGF'));
      expect(vietnameseToTelex('Tùng'), equals('Tungf'));
    });
  });

  group('VietnameseToTelexFormatter tests', () {
    final formatter = VietnameseToTelexFormatter();

    test('formats text and updates cursor properly at end', () {
      const oldValue = TextEditingValue(text: 'tun', selection: TextSelection.collapsed(offset: 3));
      const newValue = TextEditingValue(text: 'tùng', selection: TextSelection.collapsed(offset: 4));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('tungf'));
      expect(result.selection.end, equals(5));
    });

    test('handles English typing without changing', () {
      const oldValue = TextEditingValue(text: 'tun', selection: TextSelection.collapsed(offset: 3));
      const newValue = TextEditingValue(text: 'tung', selection: TextSelection.collapsed(offset: 4));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('tung'));
      expect(result.selection.end, equals(4));
    });
  });
}
