import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemAlarmResult {
  final bool isSuccess;
  final String? errorMessage;

  const SystemAlarmResult({
    required this.isSuccess,
    this.errorMessage,
  });
}

class SystemAlarmService {
  static const MethodChannel _channel = MethodChannel('com.azkari.app/alarm');

  /// Sets an alarm in the phone's native Clock app.
  /// [hour]: 0-23
  /// [minute]: 0-59
  /// [title]: Label for the alarm, e.g. "صلاة الفجر"
  /// [skipUi]: Whether to bypass the Clock UI if supported
  static Future<SystemAlarmResult> setAlarm({
    required int hour,
    required int minute,
    required String title,
    bool skipUi = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const SystemAlarmResult(
        isSuccess: false,
        errorMessage: 'ميزة منبه الهاتف مدعومة على أجهزة أندرويد فقط',
      );
    }

    try {
      final success = await _channel.invokeMethod<bool>('setAlarm', {
        'hour': hour,
        'minute': minute,
        'title': title,
        'skipUi': skipUi,
      });

      return SystemAlarmResult(isSuccess: success ?? true);
    } on PlatformException catch (e) {
      return SystemAlarmResult(
        isSuccess: false,
        errorMessage: e.message ?? 'تعذر فتح تطبيق المنبه',
      );
    } catch (e) {
      return SystemAlarmResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sets an alarm for a prayer with an optional offset in minutes (e.g. -15 for 15 mins before)
  static Future<SystemAlarmResult> setPrayerAlarm({
    required String prayerName,
    required DateTime prayerTime,
    int offsetMinutes = 0,
    bool skipUi = false,
  }) async {
    final targetTime = prayerTime.add(Duration(minutes: offsetMinutes));

    String title = 'صلاة $prayerName';
    if (offsetMinutes < 0) {
      title = 'استعداد لصلاة $prayerName (${offsetMinutes.abs()} د قبل الأذان)';
    }

    return setAlarm(
      hour: targetTime.hour,
      minute: targetTime.minute,
      title: title,
      skipUi: skipUi,
    );
  }

  /// Opens the device's native Clock / Alarm app
  static Future<SystemAlarmResult> openAlarmApp() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const SystemAlarmResult(
        isSuccess: false,
        errorMessage: 'ميزة منبه الهاتف مدعومة على أجهزة أندرويد فقط',
      );
    }

    try {
      final success = await _channel.invokeMethod<bool>('openAlarmApp');
      return SystemAlarmResult(isSuccess: success ?? true);
    } on PlatformException catch (e) {
      return SystemAlarmResult(
        isSuccess: false,
        errorMessage: e.message ?? 'تعذر فتح تطبيق المنبه',
      );
    }
  }
}
