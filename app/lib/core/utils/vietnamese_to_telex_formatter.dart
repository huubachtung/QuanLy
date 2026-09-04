import 'package:flutter/services.dart';

/// Metadata for a Vietnamese character with its base character, hat/modifier, and tone mark.
class _VnCharInfo {
  final String base;
  final String? tone; // 's', 'f', 'r', 'x', 'j'

  const _VnCharInfo(this.base, [this.tone]);
}

/// Map of all Vietnamese accented characters to their base Latin representation and tone.
const Map<String, _VnCharInfo> _vnCharMap = {
  // a
  'à': _VnCharInfo('a', 'f'),
  'á': _VnCharInfo('a', 's'),
  'ả': _VnCharInfo('a', 'r'),
  'ã': _VnCharInfo('a', 'x'),
  'ạ': _VnCharInfo('a', 'j'),
  // â
  'â': _VnCharInfo('aa'),
  'ầ': _VnCharInfo('aa', 'f'),
  'ấ': _VnCharInfo('aa', 's'),
  'ẩ': _VnCharInfo('aa', 'r'),
  'ẫ': _VnCharInfo('aa', 'x'),
  'ậ': _VnCharInfo('aa', 'j'),
  // ă
  'ă': _VnCharInfo('aw'),
  'ằ': _VnCharInfo('aw', 'f'),
  'ắ': _VnCharInfo('aw', 's'),
  'ẳ': _VnCharInfo('aw', 'r'),
  'ẵ': _VnCharInfo('aw', 'x'),
  'ặ': _VnCharInfo('aw', 'j'),
  // e
  'è': _VnCharInfo('e', 'f'),
  'é': _VnCharInfo('e', 's'),
  'ẻ': _VnCharInfo('e', 'r'),
  'ẽ': _VnCharInfo('e', 'x'),
  'ẹ': _VnCharInfo('e', 'j'),
  // ê
  'ê': _VnCharInfo('ee'),
  'ề': _VnCharInfo('ee', 'f'),
  'ế': _VnCharInfo('ee', 's'),
  'ể': _VnCharInfo('ee', 'r'),
  'ễ': _VnCharInfo('ee', 'x'),
  'ệ': _VnCharInfo('ee', 'j'),
  // i
  'ì': _VnCharInfo('i', 'f'),
  'í': _VnCharInfo('i', 's'),
  'ỉ': _VnCharInfo('i', 'r'),
  'ĩ': _VnCharInfo('i', 'x'),
  'ị': _VnCharInfo('i', 'j'),
  // o
  'ò': _VnCharInfo('o', 'f'),
  'ó': _VnCharInfo('o', 's'),
  'ỏ': _VnCharInfo('o', 'r'),
  'õ': _VnCharInfo('o', 'x'),
  'ọ': _VnCharInfo('o', 'j'),
  // ô
  'ô': _VnCharInfo('oo'),
  'ồ': _VnCharInfo('oo', 'f'),
  'ố': _VnCharInfo('oo', 's'),
  'ổ': _VnCharInfo('oo', 'r'),
  'ỗ': _VnCharInfo('oo', 'x'),
  'ộ': _VnCharInfo('oo', 'j'),
  // ơ
  'ơ': _VnCharInfo('ow'),
  'ờ': _VnCharInfo('ow', 'f'),
  'ớ': _VnCharInfo('ow', 's'),
  'ở': _VnCharInfo('ow', 'r'),
  'ỡ': _VnCharInfo('ow', 'x'),
  'ợ': _VnCharInfo('ow', 'j'),
  // u
  'ù': _VnCharInfo('u', 'f'),
  'ú': _VnCharInfo('u', 's'),
  'ủ': _VnCharInfo('u', 'r'),
  'ũ': _VnCharInfo('u', 'x'),
  'ụ': _VnCharInfo('u', 'j'),
  // ư
  'ư': _VnCharInfo('uw'),
  'ừ': _VnCharInfo('uw', 'f'),
  'ứ': _VnCharInfo('uw', 's'),
  'ử': _VnCharInfo('uw', 'r'),
  'ữ': _VnCharInfo('uw', 'x'),
  'ự': _VnCharInfo('uw', 'j'),
  // y
  'ỳ': _VnCharInfo('y', 'f'),
  'ý': _VnCharInfo('y', 's'),
  'ỷ': _VnCharInfo('y', 'r'),
  'ỹ': _VnCharInfo('y', 'x'),
  'ỵ': _VnCharInfo('y', 'j'),
  // d
  'đ': _VnCharInfo('dd'),

  // UPPERCASE
  'À': _VnCharInfo('A', 'f'),
  'Á': _VnCharInfo('A', 's'),
  'Ả': _VnCharInfo('A', 'r'),
  'Ã': _VnCharInfo('A', 'x'),
  'Ạ': _VnCharInfo('A', 'j'),
  'Â': _VnCharInfo('AA'),
  'Ầ': _VnCharInfo('AA', 'f'),
  'Ấ': _VnCharInfo('AA', 's'),
  'Ẩ': _VnCharInfo('AA', 'r'),
  'Ẫ': _VnCharInfo('AA', 'x'),
  'Ậ': _VnCharInfo('AA', 'j'),
  'Ă': _VnCharInfo('AW'),
  'Ằ': _VnCharInfo('AW', 'f'),
  'Ắ': _VnCharInfo('AW', 's'),
  'Ẳ': _VnCharInfo('AW', 'r'),
  'Ẵ': _VnCharInfo('AW', 'x'),
  'Ặ': _VnCharInfo('AW', 'j'),
  'È': _VnCharInfo('E', 'f'),
  'É': _VnCharInfo('E', 's'),
  'Ẻ': _VnCharInfo('E', 'r'),
  'Ẽ': _VnCharInfo('E', 'x'),
  'Ẹ': _VnCharInfo('E', 'j'),
  'Ê': _VnCharInfo('EE'),
  'Ề': _VnCharInfo('EE', 'f'),
  'Ế': _VnCharInfo('EE', 's'),
  'Ể': _VnCharInfo('EE', 'r'),
  'Ễ': _VnCharInfo('EE', 'x'),
  'Ệ': _VnCharInfo('EE', 'j'),
  'Ì': _VnCharInfo('I', 'f'),
  'Í': _VnCharInfo('I', 's'),
  'Ỉ': _VnCharInfo('I', 'r'),
  'Ĩ': _VnCharInfo('I', 'x'),
  'Ị': _VnCharInfo('I', 'j'),
  'Ò': _VnCharInfo('O', 'f'),
  'Ó': _VnCharInfo('O', 's'),
  'Ỏ': _VnCharInfo('O', 'r'),
  'Õ': _VnCharInfo('O', 'x'),
  'Ọ': _VnCharInfo('O', 'j'),
  'Ô': _VnCharInfo('OO'),
  'Ồ': _VnCharInfo('OO', 'f'),
  'Ố': _VnCharInfo('OO', 's'),
  'Ổ': _VnCharInfo('OO', 'r'),
  'Ỗ': _VnCharInfo('OO', 'x'),
  'Ộ': _VnCharInfo('OO', 'j'),
  'Ơ': _VnCharInfo('OW'),
  'Ờ': _VnCharInfo('OW', 'f'),
  'Ớ': _VnCharInfo('OW', 's'),
  'Ở': _VnCharInfo('OW', 'r'),
  'Ỡ': _VnCharInfo('OW', 'x'),
  'Ợ': _VnCharInfo('OW', 'j'),
  'Ù': _VnCharInfo('U', 'f'),
  'Ú': _VnCharInfo('U', 's'),
  'Ủ': _VnCharInfo('U', 'r'),
  'Ũ': _VnCharInfo('U', 'x'),
  'Ụ': _VnCharInfo('U', 'j'),
  'Ư': _VnCharInfo('UW'),
  'Ừ': _VnCharInfo('UW', 'f'),
  'Ứ': _VnCharInfo('UW', 's'),
  'Ử': _VnCharInfo('UW', 'r'),
  'Ữ': _VnCharInfo('UW', 'x'),
  'Ự': _VnCharInfo('UW', 'j'),
  'Ỳ': _VnCharInfo('Y', 'f'),
  'Ý': _VnCharInfo('Y', 's'),
  'Ỷ': _VnCharInfo('Y', 'r'),
  'Ỹ': _VnCharInfo('Y', 'x'),
  'Ỵ': _VnCharInfo('Y', 'j'),
  'Đ': _VnCharInfo('DD'),
};

/// Regex to find words containing alphabetical and Vietnamese characters.
final RegExp _wordRegExp = RegExp(r'[a-zA-Z\u00C0-\u1EF9]+');

/// Converts a single word (token of letters) with Vietnamese diacritics into Telex ASCII.
/// Example: "tùng" -> "tungf", "nguyễn" -> "nguyeenx", "đạt" -> "ddatj", "cường" -> "cuowngf".
String _convertWordToTelex(String word) {
  bool hasVietnamese = false;
  for (int i = 0; i < word.length; i++) {
    if (_vnCharMap.containsKey(word[i])) {
      hasVietnamese = true;
      break;
    }
  }

  if (!hasVietnamese) return word;

  final buffer = StringBuffer();
  String? foundTone;
  bool isAllUpper = word == word.toUpperCase() && word.length > 1;

  for (int i = 0; i < word.length; i++) {
    final ch = word[i];
    final nextCh = (i + 1 < word.length) ? word[i + 1] : null;

    // Special handling for ươ / ƯƠ
    // In Telex typing: u + o + w -> ươ
    final isUo = (ch == 'ư' || ch == 'ừ' || ch == 'ứ' || ch == 'ử' || ch == 'ữ' || ch == 'ự') &&
        (nextCh != null && (nextCh == 'ơ' || nextCh == 'ờ' || nextCh == 'ớ' || nextCh == 'ở' || nextCh == 'ỡ' || nextCh == 'ợ'));

    final isUoUpper = (ch == 'Ư' || ch == 'Ừ' || ch == 'Ứ' || ch == 'Ử' || ch == 'Ữ' || ch == 'Ự') &&
        (nextCh != null && (nextCh == 'Ơ' || nextCh == 'Ờ' || nextCh == 'Ớ' || nextCh == 'Ở' || nextCh == 'Ỡ' || nextCh == 'Ợ'));

    if (isUo || isUoUpper) {
      final uInfo = _vnCharMap[ch];
      final oInfo = _vnCharMap[nextCh];
      foundTone ??= uInfo?.tone ?? oInfo?.tone;
      buffer.write(isUoUpper ? 'UOW' : 'uow');
      i++; // skip next char
      continue;
    }

    final info = _vnCharMap[ch];
    if (info != null) {
      buffer.write(info.base);
      foundTone ??= info.tone;
    } else {
      buffer.write(ch);
    }
  }

  // Append tone mark at the end of the word if any
  if (foundTone != null) {
    buffer.write(isAllUpper ? foundTone.toUpperCase() : foundTone);
  }

  return buffer.toString();
}

/// Converts any string containing Vietnamese text into Telex ASCII representation.
/// E.g. "tùng" -> "tungf", "tùng123" -> "tungf123", "việt" -> "vieetj".
String vietnameseToTelex(String text) {
  if (text.isEmpty) return text;

  return text.replaceAllMapped(_wordRegExp, (match) {
    return _convertWordToTelex(match.group(0)!);
  });
}

/// A [TextInputFormatter] that automatically intercepts any Vietnamese accented characters
/// and converts them into Telex ASCII keystrokes, ensuring only English characters are accepted.
class VietnameseToTelexFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final converted = vietnameseToTelex(newValue.text);
    if (converted == newValue.text) {
      return newValue;
    }

    // Calculate new cursor offset
    int newOffset;
    if (newValue.selection.end >= newValue.text.length) {
      newOffset = converted.length;
    } else if (newValue.selection.end <= 0) {
      newOffset = 0;
    } else {
      final textBeforeCursor = newValue.text.substring(0, newValue.selection.end);
      final convertedBefore = vietnameseToTelex(textBeforeCursor);
      newOffset = convertedBefore.length;
    }
    newOffset = newOffset.clamp(0, converted.length);

    return TextEditingValue(
      text: converted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
