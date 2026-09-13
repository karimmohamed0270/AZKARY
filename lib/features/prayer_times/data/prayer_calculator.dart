import 'package:adhan/adhan.dart';
import '../models/prayer_times_model.dart';

class PrayerCalculator {
  /// Calculate prayer times for a given date, coordinates, method, and madhab
  static PrayerTimesModel calculate({
    required double latitude,
    required double longitude,
    required String cityName,
    required bool isGps,
    String method = 'egyptian',
    String madhab = 'shafi',
    int fajrAdjustment = 0,
    int sunriseAdjustment = 0,
    int dhuhrAdjustment = 0,
    int asrAdjustment = 0,
    int maghribAdjustment = 0,
    int ishaAdjustment = 0,
    DateTime? targetDate,
  }) {
    final date = targetDate ?? DateTime.now();
    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParameters(method);

    if (madhab.toLowerCase() == 'hanafi') {
      params.madhab = Madhab.hanafi;
    } else {
      params.madhab = Madhab.shafi;
    }

    // Apply manual minute adjustments
    params.adjustments.fajr = fajrAdjustment;
    params.adjustments.sunrise = sunriseAdjustment;
    params.adjustments.dhuhr = dhuhrAdjustment;
    params.adjustments.asr = asrAdjustment;
    params.adjustments.maghrib = maghribAdjustment;
    params.adjustments.isha = ishaAdjustment;

    final dateComponents = DateComponents.from(date);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Calculate Next Prayer and Remaining Duration
    final now = DateTime.now();
    String nextName = 'الفجر';
    DateTime nextTime = prayerTimes.fajr;

    if (now.isBefore(prayerTimes.fajr)) {
      nextName = 'الفجر';
      nextTime = prayerTimes.fajr;
    } else if (now.isBefore(prayerTimes.sunrise)) {
      nextName = 'الشروق';
      nextTime = prayerTimes.sunrise;
    } else if (now.isBefore(prayerTimes.dhuhr)) {
      nextName = 'الظهر';
      nextTime = prayerTimes.dhuhr;
    } else if (now.isBefore(prayerTimes.asr)) {
      nextName = 'العصر';
      nextTime = prayerTimes.asr;
    } else if (now.isBefore(prayerTimes.maghrib)) {
      nextName = 'المغرب';
      nextTime = prayerTimes.maghrib;
    } else if (now.isBefore(prayerTimes.isha)) {
      nextName = 'العشاء';
      nextTime = prayerTimes.isha;
    } else {
      // After Isha: Next is tomorrow's Fajr
      final tomorrow = date.add(const Duration(days: 1));
      final tomorrowComponents = DateComponents.from(tomorrow);
      final tomorrowPrayers = PrayerTimes(coordinates, tomorrowComponents, params);
      nextName = 'الفجر';
      nextTime = tomorrowPrayers.fajr;
    }

    Duration remaining = nextTime.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    return PrayerTimesModel(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      nextPrayerName: nextName,
      nextPrayerTime: nextTime,
      timeRemaining: remaining,
      cityName: cityName,
      isGps: isGps,
    );
  }

  static CalculationParameters _getCalculationParameters(String method) {
    switch (method.toLowerCase()) {
      case 'makkah':
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'muslim_world_league':
      case 'mwl':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'north_america':
      case 'isna':
        return CalculationMethod.north_america.getParameters();
      case 'turkey':
        return CalculationMethod.turkey.getParameters();
      case 'singapore':
        return CalculationMethod.singapore.getParameters();
      case 'egyptian':
      default:
        return CalculationMethod.egyptian.getParameters();
    }
  }
}
