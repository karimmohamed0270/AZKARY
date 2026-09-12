import 'package:flutter_test/flutter_test.dart';
import 'package:azkari/core/services/notification_service.dart';
import 'package:azkari/core/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Configuration Tests', () {
    test('Channel IDs and names are properly defined', () {
      expect(NotificationService.prayerChannelId, 'prayer_adhan_channel_v3');
      expect(NotificationService.azkarChannelId, 'azkar_reminder_channel_v2');
      expect(NotificationService.prayerChannelName, 'مواقيت الصلاة والأذان');
      expect(NotificationService.azkarChannelName, 'تذكير الأذكار اليومية');
    });
  });

  group('AudioService Basic Lifecycle Tests', () {
    test('AudioService can be instantiated and initialized without crashing', () {
      final audioService = AudioService();
      expect(audioService.isPlaying, isFalse);
      audioService.dispose();
    });
  });
}
