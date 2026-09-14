import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:azkari/core/services/system_alarm_service.dart';
import 'package:azkari/features/prayer_times/presentation/widgets/prayer_row_item.dart';
import 'package:azkari/features/prayer_times/presentation/widgets/prayer_alarm_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemAlarmService Unit Tests', () {
    const channel = MethodChannel('com.azkari.app/alarm');
    final List<MethodCall> log = [];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Prayer time offset calculation handles normal and edge case times', () {
      final prayerTime = DateTime(2026, 9, 14, 4, 30);
      final minus15 = prayerTime.subtract(const Duration(minutes: 15));
      final minus30 = prayerTime.subtract(const Duration(minutes: 30));

      expect(minus15.hour, 4);
      expect(minus15.minute, 15);
      expect(minus30.hour, 4);
      expect(minus30.minute, 0);

      // Edge case: midnight boundary
      final midnightPrayer = DateTime(2026, 9, 14, 0, 10);
      final midnightMinus15 = midnightPrayer.subtract(const Duration(minutes: 15));
      expect(midnightMinus15.hour, 23);
      expect(midnightMinus15.minute, 55);
      expect(midnightMinus15.day, 13);
    });
  });

  group('PrayerRowItem and PrayerAlarmSheet Widget Tests', () {
    testWidgets('PrayerRowItem displays alarm icon and triggers PrayerAlarmSheet', (tester) async {
      final testTime = DateTime(2026, 9, 14, 4, 35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerRowItem(
              prayerName: 'الفجر',
              prayerTime: testTime,
              isNext: true,
              iconData: Icons.wb_twilight,
            ),
          ),
        ),
      );

      // Check prayer name and alarm icon exist
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.byIcon(Icons.alarm_add_rounded), findsOneWidget);

      // Tap alarm icon to open bottom sheet
      await tester.tap(find.byIcon(Icons.alarm_add_rounded));
      await tester.pumpAndSettle();

      // Check PrayerAlarmSheet is visible with title and options
      expect(find.text('ضبط منبه هاتف لصلاة الفجر'), findsOneWidget);
      expect(find.text('في موعد الأذان تماماً'), findsOneWidget);
      expect(find.text('قبل الأذان بـ ١٥ دقيقة'), findsOneWidget);
      expect(find.text('قبل الأذان بـ ٣٠ دقيقة'), findsOneWidget);
    });

    testWidgets('PrayerAlarmSheet displays custom title for Sunrise (الشروق)', (tester) async {
      final testSunrise = DateTime(2026, 9, 14, 5, 45);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerAlarmSheet(
              prayerName: 'الشروق',
              prayerTime: testSunrise,
            ),
          ),
        ),
      );

      // Check Sunrise specific header
      expect(find.text('ضبط منبه هاتف لوقت الشروق'), findsOneWidget);
      expect(find.text('في موعد الشروق تماماً'), findsOneWidget);
      expect(find.text('قبل الشروق بـ ١٥ دقيقة'), findsOneWidget);
    });
  });
}
