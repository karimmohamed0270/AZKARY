import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String prayerChannelId = 'prayer_adhan_channel_v3';
  static const String prayerChannelName = 'مواقيت الصلاة والأذان';
  static const String prayerChannelDesc =
      'تنبيهات صوت الأذان ومواقيت الصلاة المفروضة';

  static const String azkarChannelId = 'azkar_reminder_channel_v2';
  static const String azkarChannelName = 'تذكير الأذكار اليومية';
  static const String azkarChannelDesc = 'تنبيهات أذكار الصباح والمساء';

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezone database and configure device local timezone
    await _configureLocalTimezone();

    // 2. Settings for Android & iOS
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 3. Create Android Notification Channels (Required on Android 8.0+)
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Remove deprecated / outdated channels so new audio config takes effect
      try {
        await androidImpl.deleteNotificationChannel('prayer_adhan_channel');
        await androidImpl.deleteNotificationChannel('azkar_reminder_channel');
      } catch (_) {}

      // High priority Prayer channel with Adhan audio
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          prayerChannelId,
          prayerChannelName,
          description: prayerChannelDesc,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Daily Azkar reminder channel with gentle chime audio
      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          azkarChannelId,
          azkarChannelName,
          description: azkarChannelDesc,
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('azkar_tone'),
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    _isInitialized = true;
  }

  /// Configure local timezone with robust fallbacks
  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      return;
    } catch (e) {
      debugPrint('Could not set timezone automatically by identifier: $e');
    }

    // Fallback: match by current device UTC offset
    try {
      final offset = DateTime.now().timeZoneOffset;
      final fallbackTz = _getFallbackTimezoneForOffset(offset);
      tz.setLocalLocation(tz.getLocation(fallbackTz));
    } catch (e) {
      debugPrint('Fallback timezone offset failed: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {}
    }
  }

  String _getFallbackTimezoneForOffset(Duration offset) {
    final hours = offset.inHours;
    switch (hours) {
      case 2:
        return 'Africa/Cairo';
      case 3:
        return 'Asia/Riyadh';
      case 4:
        return 'Asia/Dubai';
      case 1:
        return 'Africa/Algiers';
      default:
        return 'UTC';
    }
  }

  /// Request notification permissions (Android 13+ & iOS & Exact Alarms)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await init();

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Android 13+ runtime POST_NOTIFICATIONS permission
      final notifGranted =
          await androidImpl.requestNotificationsPermission() ?? false;

      // Android 12+ Exact alarm permission
      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (_) {}

      return notifGranted;
    }

    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Request exact alarm permission if required on Android 12+
  Future<bool?> requestExactAlarmsPermission() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        return await androidImpl.requestExactAlarmsPermission();
      } catch (_) {}
    }
    return true;
  }

  /// Schedule local notification for a specific prayer
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) await init();

    if (scheduledTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      prayerChannelId,
      prayerChannelName,
      channelDescription: prayerChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'adhan.mp3',
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // If exact alarms are restricted by system, fallback to inexact
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (err) {
        debugPrint('Failed to schedule prayer notification: $err');
      }
    }
  }

  /// Schedule daily reminder for Morning / Evening Azkar
  Future<void> scheduleDailyAzkarNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await init();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      azkarChannelId,
      azkarChannelName,
      channelDescription: azkarChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('azkar_tone'),
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'azkar_tone.mp3',
      ),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (err) {
        debugPrint('Failed to schedule azkar notification: $err');
      }
    }
  }

  /// Send an immediate test notification with real Adhan sound
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await init();
    await requestPermissions();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      prayerChannelId,
      prayerChannelName,
      channelDescription: prayerChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: 'adhan.mp3',
      ),
    );

    await _notificationsPlugin.show(
      888,
      title,
      body,
      notificationDetails,
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
