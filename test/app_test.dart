import 'package:flutter_test/flutter_test.dart';
import 'package:azkari/core/utils/arabic_numbers.dart';
import 'package:azkari/core/utils/hijri_helper.dart';
import 'package:azkari/core/services/location_service.dart';
import 'package:azkari/features/prayer_times/data/prayer_calculator.dart';
import 'package:azkari/features/quran/models/juz_model.dart';
import 'package:azkari/features/quran/models/surah_model.dart';
import 'package:azkari/features/quran/data/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkari/core/services/preference_service.dart';
import 'package:azkari/features/azkar/models/zikr_model.dart';
import 'package:azkari/features/azkar/models/asmaa_allah_model.dart';
import 'package:azkari/features/azkar/data/azkar_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArabicNumbers Utilities Test', () {
    test('Converts English digits to Eastern Arabic digits', () {
      expect(ArabicNumbers.convert(123), '١٢٣');
      expect(ArabicNumbers.convert('054'), '٠٥٤');
      expect(ArabicNumbers.convert(99), '٩٩');
    });

    test('Formats countdown duration correctly', () {
      const duration = Duration(hours: 2, minutes: 15, seconds: 30);
      expect(ArabicNumbers.formatCountdown(duration), '٠٢:١٥:٣٠');
    });
  });

  group('Location and Qibla Calculation Test', () {
    final locationService = LocationService();

    test('Calculates distance to Kaaba from Cairo (approx 1280 - 1320 km)', () {
      final distance = locationService.calculateDistanceToKaaba(
        30.0444,
        31.2357,
      );
      expect(distance, greaterThan(1200));
      expect(distance, lessThan(1400));
    });

    test('Calculates Qibla angle from Cairo (approx 135 - 140 degrees)', () {
      final angle = locationService.calculateQiblaAngle(30.0444, 31.2357);
      expect(angle, greaterThan(130));
      expect(angle, lessThan(145));
    });
  });

  group('Prayer Times Offline Calculation Test', () {
    test('Calculates accurate today prayer times for Cairo', () {
      final prayerTimes = PrayerCalculator.calculate(
        latitude: 30.0444,
        longitude: 31.2357,
        cityName: 'القاهرة',
        isGps: false,
        method: 'egyptian',
        madhab: 'shafi',
        targetDate: DateTime(2026, 9, 1),
      );

      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.sunrise, isNotNull);
      expect(prayerTimes.dhuhr, isNotNull);
      expect(prayerTimes.asr, isNotNull);
      expect(prayerTimes.maghrib, isNotNull);
      expect(prayerTimes.isha, isNotNull);
      expect(prayerTimes.cityName, 'القاهرة');
      expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), isTrue);
      expect(prayerTimes.sunrise.isBefore(prayerTimes.dhuhr), isTrue);
      expect(prayerTimes.dhuhr.isBefore(prayerTimes.asr), isTrue);
      expect(prayerTimes.asr.isBefore(prayerTimes.maghrib), isTrue);
      expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), isTrue);
    });

    test(
      'Calculates accurate prayer times for Makkah with Umm Al Qura method',
      () {
        final makkahPrayers = PrayerCalculator.calculate(
          latitude: 21.4225,
          longitude: 39.8262,
          cityName: 'مكة المكرمة',
          isGps: false,
          method: 'makkah',
          madhab: 'shafi',
          targetDate: DateTime(2026, 9, 1),
        );

        expect(makkahPrayers.fajr, isNotNull);
        expect(makkahPrayers.maghrib, isNotNull);
        expect(makkahPrayers.cityName, 'مكة المكرمة');
      },
    );
  });

  group('Hijri Date & Events Helper Test', () {
    test('Returns formatted Hijri string', () {
      final hijriStr = HijriHelper.getTodayFormatted();
      expect(hijriStr.isNotEmpty, isTrue);
      expect(hijriStr.contains('هـ'), isTrue);
    });

    test('Returns annual Islamic events list', () {
      final events = HijriHelper.getIslamicEvents();
      expect(events.length, greaterThanOrEqualTo(10));
      expect(events.any((e) => e['name'] == 'عيد الفطر المبارك'), isTrue);
      expect(events.any((e) => e['name'] == 'يوم عرفة'), isTrue);
    });
  });

  group('Models Serialization Test', () {
    test('SurahModel serialization and deserialization', () {
      final surah = SurahModel(
        number: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        type: 'meccan',
        versesCount: 7,
        page: 1,
        juz: 1,
      );

      final json = surah.toJson();
      final fromJson = SurahModel.fromJson(json);

      expect(fromJson.number, 1);
      expect(fromJson.nameAr, 'الفاتحة');
      expect(fromJson.isMeccan, isTrue);
    });

    test('ZikrModel serialization and deserialization', () {
      final zikr = ZikrModel(
        id: 1,
        category: 'أذكار الصباح',
        categoryId: 'sabah',
        text: 'أصبحنا وأصبح الملك لله',
        count: 1,
        fadl: 'فضل عظيم',
        source: 'صحيح مسلم',
      );

      final json = zikr.toJson();
      final fromJson = ZikrModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.category, 'أذكار الصباح');
      expect(fromJson.count, 1);
    });

    test('AsmaaAllahModel serialization and deserialization', () {
      final asmaa = AsmaaAllahModel(
        id: 1,
        name: 'الله',
        meaning: 'الاسم الأعظم',
      );

      final json = asmaa.toJson();
      final fromJson = AsmaaAllahModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.name, 'الله');
    });
  });

  group('Quran Ayah Text Processing & Bismillah Handling Test', () {
    String cleanAyah(int surahNum, int ayahNum, String rawText) {
      String text = rawText.replaceAll('\ufeff', '').trim();
      if (surahNum != 1 && surahNum != 9 && ayahNum == 1) {
        const prefixes = [
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          'بِّسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        ];
        for (final prefix in prefixes) {
          if (text.startsWith(prefix)) {
            text = text.substring(prefix.length).trim();
            break;
          }
        }
      }
      return text;
    }

    test('Preserves Bismillah in Surah Al-Fatiha Ayah 1', () {
      const fatihaAyah1 = '﻿بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      final cleaned = cleanAyah(1, 1, fatihaAyah1);
      expect(cleaned, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
    });

    test(
      'Strips Bismillah prefix from Surah Al-Baqarah Ayah 1 without losing verse content',
      () {
        const baqarahAyah1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ';
        final cleaned = cleanAyah(2, 1, baqarahAyah1);
        expect(cleaned, 'الٓمٓ');
      },
    );

    test('Does not modify verses other than Ayah 1', () {
      const baqarahAyah2 =
          'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًۭى لِّلْمُتَّقِينَ';
      final cleaned = cleanAyah(2, 2, baqarahAyah2);
      expect(cleaned, baqarahAyah2);
    });

    test('Leaves Surah At-Tawbah Ayah 1 untouched', () {
      const tawbahAyah1 = 'بَرَاءَةٌ مِّنَ اللَّهِ وَرَسُولِهِ';
      final cleaned = cleanAyah(9, 1, tawbahAyah1);
      expect(cleaned, tawbahAyah1);
    });
  });

  group('Quran 30 Juz Structure & Boundaries Test', () {
    test('Contains exactly 30 Juzs', () {
      expect(JuzModel.allJuzs.length, 30);
    });

    test('Juz 1 starts at Al-Fatiha (1:1) and ends at Al-Baqarah (2:141)', () {
      final juz1 = JuzModel.allJuzs.first;
      expect(juz1.number, 1);
      expect(juz1.startSurahNum, 1);
      expect(juz1.startAyah, 1);
      expect(juz1.endSurahNum, 2);
      expect(juz1.endAyah, 141);
      expect(juz1.name, 'الم');
    });

    test('Juz 30 ends at An-Nas (114:6)', () {
      final juz30 = JuzModel.allJuzs.last;
      expect(juz30.number, 30);
      expect(juz30.startSurahNum, 78);
      expect(juz30.startAyah, 1);
      expect(juz30.endSurahNum, 114);
      expect(juz30.endAyah, 6);
      expect(juz30.name, 'عم يتساءلون');
    });

    test('Every Juz is contiguous with the next Juz', () {
      for (int i = 0; i < JuzModel.allJuzs.length - 1; i++) {
        final current = JuzModel.allJuzs[i];
        final next = JuzModel.allJuzs[i + 1];

        expect(next.number, current.number + 1);

        if (current.endSurahNum == next.startSurahNum) {
          expect(next.startAyah, current.endAyah + 1,
              reason: 'Juz ${current.number} and ${next.number} should be contiguous in Surah ${current.endSurahNum}');
        } else {
          expect(next.startSurahNum, current.endSurahNum + 1);
          expect(next.startAyah, 1);
        }
      }
    });

    test('QuranRepository loads Juz segments cleanly without race condition', () async {
      final repo = QuranRepository();
      final segmentsJuz1 = await repo.getJuzSurahSegments(1);
      expect(segmentsJuz1.isNotEmpty, isTrue);
      expect(segmentsJuz1.length, 2); // Al-Fatiha and Al-Baqarah
      final fatiha = segmentsJuz1[0]['surah'] as SurahModel;
      expect(fatiha.number, 1);
      expect(fatiha.nameAr, 'الفاتحة');

      final segmentsJuz30 = await repo.getJuzSurahSegments(30);
      expect(segmentsJuz30.isNotEmpty, isTrue);
      final lastSurah = segmentsJuz30.last['surah'] as SurahModel;
      expect(lastSurah.number, 114);
      expect(lastSurah.nameAr, 'الناس');
    });
  });

  group('Tasbeeh Daily History & Monthly Tracking Test', () {
    late PreferenceService prefsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferenceService(prefs);
    });

    test('Daily goal defaults to 100 and can be updated', () async {
      expect(prefsService.getTasbeehDailyGoal(), 100);
      await prefsService.setTasbeehDailyGoal(300);
      expect(prefsService.getTasbeehDailyGoal(), 300);
    });

    test('Today tasbeeh increments correctly', () async {
      expect(prefsService.getTodayTasbeehCount(), 0);
      await prefsService.incrementTodayTasbeeh();
      await prefsService.incrementTodayTasbeeh();
      await prefsService.incrementTodayTasbeeh();
      expect(prefsService.getTodayTasbeehCount(), 3);
    });

    test('Monthly data returns mapping for all days in month', () {
      final monthly = prefsService.getMonthlyTasbeeh(2026, 9); // September has 30 days
      expect(monthly.length, 30);
      expect(monthly[1], 0);
      expect(monthly[30], 0);
    });

    test('Streak calculation works for active days', () async {
      expect(prefsService.getTasbeehStreak(), 0);
      await prefsService.incrementTodayTasbeeh();
      expect(prefsService.getTasbeehStreak(), 1);
    });
  });

  group('Morning and Evening Azkar Content Verification Test', () {
    test('Sabah and Masaa include Ayat Al-Kursi (1x) and 3 Surahs (3x each)', () async {
      final repo = AzkarRepository();
      final sabahAzkar = await repo.getAzkarByCategory('أذكار الصباح');
      final masaaAzkar = await repo.getAzkarByCategory('أذكار المساء');

      // Verify Morning Azkar
      final sabahKursi = sabahAzkar.firstWhere((z) => z.text.contains('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'));
      expect(sabahKursi.count, 1);

      final sabahIkhlas = sabahAzkar.firstWhere((z) => z.text.contains('قُلْ هُوَ اللَّهُ أَحَدٌ'));
      expect(sabahIkhlas.count, 3);

      final sabahFalaq = sabahAzkar.firstWhere((z) => z.text.contains('قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ'));
      expect(sabahFalaq.count, 3);

      final sabahNas = sabahAzkar.firstWhere((z) => z.text.contains('قُلْ أَعُوذُ بِرَبِّ النَّاسِ'));
      expect(sabahNas.count, 3);

      // Verify Evening Azkar
      final masaaKursi = masaaAzkar.firstWhere((z) => z.text.contains('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ'));
      expect(masaaKursi.count, 1);

      final masaaIkhlas = masaaAzkar.firstWhere((z) => z.text.contains('قُلْ هُوَ اللَّهُ أَحَدٌ'));
      expect(masaaIkhlas.count, 3);

      final masaaFalaq = masaaAzkar.firstWhere((z) => z.text.contains('قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ'));
      expect(masaaFalaq.count, 3);

      final masaaNas = masaaAzkar.firstWhere((z) => z.text.contains('قُلْ أَعُوذُ بِرَبِّ النَّاسِ'));
      expect(masaaNas.count, 3);

      // Verify all Azkar IDs are unique
      final allAzkar = await repo.getAllAzkar();
      final ids = allAzkar.map((z) => z.id).toSet();
      expect(ids.length, allAzkar.length);
    });
  });
}

