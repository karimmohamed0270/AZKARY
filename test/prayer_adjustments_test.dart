import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkari/core/services/preference_service.dart';
import 'package:azkari/features/prayer_times/data/prayer_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerCalculator Adjustments Tests', () {
    test('PrayerCalculator accurately applies positive and negative minute adjustments', () {
      const lat = 30.0444;
      const lng = 31.2357;
      final testDate = DateTime(2026, 9, 13, 10, 0);

      final baseline = PrayerCalculator.calculate(
        latitude: lat,
        longitude: lng,
        cityName: 'القاهرة',
        isGps: false,
        targetDate: testDate,
      );

      final adjusted = PrayerCalculator.calculate(
        latitude: lat,
        longitude: lng,
        cityName: 'القاهرة',
        isGps: false,
        fajrAdjustment: 3,
        dhuhrAdjustment: -2,
        asrAdjustment: 1,
        maghribAdjustment: 4,
        ishaAdjustment: -5,
        targetDate: testDate,
      );

      // Verify Fajr is +3 minutes
      expect(adjusted.fajr.difference(baseline.fajr).inMinutes, equals(3));

      // Verify Dhuhr is -2 minutes
      expect(adjusted.dhuhr.difference(baseline.dhuhr).inMinutes, equals(-2));

      // Verify Asr is +1 minute
      expect(adjusted.asr.difference(baseline.asr).inMinutes, equals(1));

      // Verify Maghrib is +4 minutes
      expect(adjusted.maghrib.difference(baseline.maghrib).inMinutes, equals(4));

      // Verify Isha is -5 minutes
      expect(adjusted.isha.difference(baseline.isha).inMinutes, equals(-5));
    });
  });

  group('PreferenceService Adjustments Tests', () {
    test('PreferenceService correctly saves, reads, and resets prayer adjustments', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = PreferenceService(prefs);

      expect(prefService.getFajrAdjustment(), equals(0));
      expect(prefService.getDhuhrAdjustment(), equals(0));

      await prefService.setPrayerAdjustments(
        fajr: 2,
        sunrise: 1,
        dhuhr: 3,
        asr: -1,
        maghrib: 2,
        isha: -3,
      );

      expect(prefService.getFajrAdjustment(), equals(2));
      expect(prefService.getSunriseAdjustment(), equals(1));
      expect(prefService.getDhuhrAdjustment(), equals(3));
      expect(prefService.getAsrAdjustment(), equals(-1));
      expect(prefService.getMaghribAdjustment(), equals(2));
      expect(prefService.getIshaAdjustment(), equals(-3));

      await prefService.resetPrayerAdjustments();

      expect(prefService.getFajrAdjustment(), equals(0));
      expect(prefService.getSunriseAdjustment(), equals(0));
      expect(prefService.getDhuhrAdjustment(), equals(0));
      expect(prefService.getAsrAdjustment(), equals(0));
      expect(prefService.getMaghribAdjustment(), equals(0));
      expect(prefService.getIshaAdjustment(), equals(0));
    });
  });
}
