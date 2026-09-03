import 'package:hijri/hijri_calendar.dart';
import 'arabic_numbers.dart';

class HijriHelper {
  static const List<String> arabicMonths = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الآخِر',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة'
  ];

  static const List<String> arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد'
  ];

  /// Get current Hijri Date formatted in Arabic (e.g. الثلاثاء، ١٥ رمضان ١٤٤٨ هـ)
  static String getTodayFormatted({int adjustmentDays = 0}) {
    final now = DateTime.now().add(Duration(days: adjustmentDays));
    final hijri = HijriCalendar.fromDate(now);
    final dayName = arabicDays[now.weekday - 1];
    final monthName = arabicMonths[hijri.hMonth - 1];
    final dayNum = ArabicNumbers.convert(hijri.hDay);
    final yearNum = ArabicNumbers.convert(hijri.hYear);

    return '$dayName، $dayNum $monthName $yearNum هـ';
  }

  /// Get Hijri date object
  static HijriCalendar getHijriCalendar([DateTime? date, int adjustmentDays = 0]) {
    final target = (date ?? DateTime.now()).add(Duration(days: adjustmentDays));
    return HijriCalendar.fromDate(target);
  }

  /// Check if today is a Sunnah fasting day
  static String? getFastingReminder([DateTime? date, int adjustmentDays = 0]) {
    final target = (date ?? DateTime.now()).add(Duration(days: adjustmentDays));
    final hijri = HijriCalendar.fromDate(target);

    // Mondays (1) and Thursdays (4)
    final isMondayOrThursday = target.weekday == DateTime.monday || target.weekday == DateTime.thursday;
    // White Days (13, 14, 15)
    final isWhiteDay = hijri.hDay >= 13 && hijri.hDay <= 15;
    // Day of Arafah (9 Dhul-Hijjah)
    final isArafah = hijri.hMonth == 12 && hijri.hDay == 9;
    // Ashura (10 Muharram) and Tasu'a (9 Muharram)
    final isAshura = hijri.hMonth == 1 && (hijri.hDay == 9 || hijri.hDay == 10);
    // 6 of Shawwal
    final isShawwal = hijri.hMonth == 10 && hijri.hDay > 1;

    if (isArafah) {
      return 'صيام يوم عرفة (يكفّر سنة ماضية وسنة مقبلة)';
    } else if (isAshura) {
      return 'صيام يوم عاشوراء (يكفّر سنة ماضية)';
    } else if (isWhiteDay) {
      return 'صيام الأيام البيض (${ArabicNumbers.convert(hijri.hDay)} من الشهر الهجري)';
    } else if (isMondayOrThursday) {
      final dayName = target.weekday == DateTime.monday ? 'الإثنين' : 'الخميس';
      return 'سنة صيام يوم $dayName (تُعرض فيه الأعمال على الله)';
    } else if (isShawwal) {
      return 'سنة صيام الست من شوال';
    }
    return null;
  }

  /// Get list of major Islamic annual events with their Hijri month/day
  static List<Map<String, dynamic>> getIslamicEvents() {
    return [
      {'name': 'رأس السنة الهجرية', 'month': 1, 'day': 1, 'month_name': 'محرم'},
      {'name': 'يوم عاشوراء', 'month': 1, 'day': 10, 'month_name': 'محرم'},
      {'name': 'المولد النبوي الشريف', 'month': 3, 'day': 12, 'month_name': 'ربيع الأول'},
      {'name': 'ليلة الإسراء والمعراج', 'month': 7, 'day': 27, 'month_name': 'رجب'},
      {'name': 'ليلة النصف من شعبان', 'month': 8, 'day': 15, 'month_name': 'شعبان'},
      {'name': 'بداية شهر رمضان المبارك', 'month': 9, 'day': 1, 'month_name': 'رمضان'},
      {'name': 'العشر الأواخر من رمضان', 'month': 9, 'day': 21, 'month_name': 'رمضان'},
      {'name': 'ليلة القدر (المتحرّاة)', 'month': 9, 'day': 27, 'month_name': 'رمضان'},
      {'name': 'عيد الفطر المبارك', 'month': 10, 'day': 1, 'month_name': 'شوال'},
      {'name': 'بداية العشر من ذي الحجة', 'month': 12, 'day': 1, 'month_name': 'ذو الحجة'},
      {'name': 'يوم عرفة', 'month': 12, 'day': 9, 'month_name': 'ذو الحجة'},
      {'name': 'عيد الأضحى المبارك', 'month': 12, 'day': 10, 'month_name': 'ذو الحجة'},
      {'name': 'أيام التشريق', 'month': 12, 'day': 11, 'month_name': 'ذو الحجة'},
    ];
  }
}
