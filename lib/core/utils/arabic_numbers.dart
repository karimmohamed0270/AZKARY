class ArabicNumbers {
  static const List<String> _easternDigits = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'
  ];

  /// Converts English numbers string to Eastern Arabic numerals (e.g. 123 -> ١٢٣)
  static String convert(dynamic input) {
    if (input == null) return '';
    final str = input.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      final codeUnit = char.codeUnitAt(0);
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.write(_easternDigits[codeUnit - 48]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Formats duration (hours, minutes, seconds) into formatted Arabic countdown
  static String formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return convert('$hStr:$mStr:$sStr');
    } else {
      return convert('$mStr:$sStr');
    }
  }

  /// Formats 24h DateTime into friendly Arabic 12h time string (e.g. 05:23 ص)
  static String formatTime12h(DateTime dateTime) {
    int hour = dateTime.hour;
    final int minute = dateTime.minute;
    final String period = hour >= 12 ? 'م' : 'ص';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');

    return '${convert('$hourStr:$minuteStr')} $period';
  }
}
