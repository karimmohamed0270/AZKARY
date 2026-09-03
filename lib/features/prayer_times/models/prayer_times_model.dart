class PrayerTimesModel {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final Duration timeRemaining;
  final String cityName;
  final bool isGps;

  PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.timeRemaining,
    required this.cityName,
    required this.isGps,
  });

  List<Map<String, dynamic>> toList() {
    return [
      {'name': 'الفجر', 'time': fajr, 'isNext': nextPrayerName == 'الفجر', 'icon': 'fajr'},
      {'name': 'الشروق', 'time': sunrise, 'isNext': nextPrayerName == 'الشروق', 'icon': 'sunrise'},
      {'name': 'الظهر', 'time': dhuhr, 'isNext': nextPrayerName == 'الظهر', 'icon': 'dhuhr'},
      {'name': 'العصر', 'time': asr, 'isNext': nextPrayerName == 'العصر', 'icon': 'asr'},
      {'name': 'المغرب', 'time': maghrib, 'isNext': nextPrayerName == 'المغرب', 'icon': 'maghrib'},
      {'name': 'العشاء', 'time': isha, 'isNext': nextPrayerName == 'العشاء', 'icon': 'isha'},
    ];
  }
}
