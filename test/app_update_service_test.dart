import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:azkari/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PackageInfo.setMockInitialValues(
    appName: 'أذكاري',
    packageName: 'com.azkari.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  group('AppUpdateService - Version Comparison', () {
    test('correctly detects newer versions', () {
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.1'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.1.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '2.0.0'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.0', 'v1.0.1'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0.1'), isTrue);
    });

    test('correctly rejects older or equal versions', () {
      expect(AppUpdateService.isVersionNewer('1.0.1', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('2.0.0', '1.9.9'), isFalse);
      expect(AppUpdateService.isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.0', '1.0.0'), isFalse);
    });
  });

  group('AppReleaseInfo - JSON Parsing', () {
    test('parses GitHub release response with APK correctly', () {
      final json = {
        'tag_name': 'v1.0.1',
        'name': 'إصدار 1.0.1 - تحسينات وإضافات',
        'body': '• إضافة سورة الفلق والناس\n• دعم التحديث التلقائي',
        'published_at': '2026-09-12T10:00:00Z',
        'assets': [
          {
            'name': 'AZKARY.apk',
            'browser_download_url':
                'https://github.com/karimmohamed0270/AZKARY/releases/download/v1.0.1/AZKARY.apk',
            'size': 56107172,
          }
        ]
      };

      final info = AppReleaseInfo.fromJson(json);

      expect(info.tagName, 'v1.0.1');
      expect(info.version, '1.0.1');
      expect(info.title, 'إصدار 1.0.1 - تحسينات وإضافات');
      expect(info.releaseNotes, contains('سورة الفلق'));
      expect(info.apkDownloadUrl, contains('AZKARY.apk'));
      expect(info.apkSizeBytes, 56107172);
      expect(info.publishedAt, isNotNull);
    });

    test('handles missing assets gracefully', () {
      final json = {
        'tag_name': 'v1.0.2',
        'name': '',
        'body': null,
        'assets': <dynamic>[]
      };

      final info = AppReleaseInfo.fromJson(json);

      expect(info.tagName, 'v1.0.2');
      expect(info.version, '1.0.2');
      expect(info.apkDownloadUrl, isEmpty);
      expect(info.apkSizeBytes, 0);
    });
  });

  group('AppUpdateService - HTTP API Mocking', () {
    test('returns update available when newer release exists', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v2.0.0',
            'name': 'الإصدار الثاني',
            'body': 'مزايا جديدة',
            'assets': [
              {
                'name': 'AZKARY.apk',
                'browser_download_url': 'https://example.com/AZKARY.apk',
                'size': 50000000,
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AppUpdateService(client: mockClient);
      final result = await service.checkForUpdates(manualCheck: true);

      expect(result.hasUpdate, isTrue);
      expect(result.latestRelease, isNotNull);
      expect(result.latestRelease!.version, '2.0.0');
    });

    test('returns no update when 404 Not Found is returned', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Not Found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AppUpdateService(client: mockClient);
      final result = await service.checkForUpdates(manualCheck: true);

      expect(result.hasUpdate, isFalse);
      expect(result.errorMessage, contains('أحدث إصدار'));
    });
  });
}
