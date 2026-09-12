import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppReleaseInfo {
  final String tagName;
  final String version;
  final String title;
  final String releaseNotes;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final DateTime? publishedAt;

  const AppReleaseInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    this.publishedAt,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String?) ?? '';
    final cleanVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '').trim();

    String apkUrl = '';
    int apkSize = 0;

    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          apkSize = (asset['size'] as num?)?.toInt() ?? 0;
          break;
        }
      }
    }

    DateTime? publishedDate;
    if (json['published_at'] != null) {
      publishedDate = DateTime.tryParse(json['published_at'] as String);
    }

    return AppReleaseInfo(
      tagName: tagName,
      version: cleanVersion,
      title: (json['name'] as String?)?.isNotEmpty == true
          ? json['name'] as String
          : 'تحديث جديد $tagName',
      releaseNotes: (json['body'] as String?) ?? 'تحسينات وإصلاحات عامة.',
      apkDownloadUrl: apkUrl,
      apkSizeBytes: apkSize,
      publishedAt: publishedDate,
    );
  }
}

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final AppReleaseInfo? latestRelease;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    this.latestRelease,
    this.errorMessage,
  });
}

class AppUpdateService {
  static const String repoOwner = 'karimmohamed0270';
  static const String repoName = 'AZKARY';
  static const String apiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  final http.Client _client;

  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  /// Checks GitHub releases to see if there is an update available.
  Future<UpdateCheckResult> checkForUpdates({bool manualCheck = false}) async {
    String currentVersion = '1.0.0';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }

    try {
      final response = await _client.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AZKARY-Flutter-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final releaseInfo = AppReleaseInfo.fromJson(data);

        if (releaseInfo.apkDownloadUrl.isEmpty) {
          return UpdateCheckResult(
            hasUpdate: false,
            currentVersion: currentVersion,
            errorMessage: manualCheck
                ? 'يوجد إصدار جديد على GitHub ولكن لم يتم إرفاق ملف APK به بعد.'
                : null,
          );
        }

        final isNewer = isVersionNewer(currentVersion, releaseInfo.version);

        return UpdateCheckResult(
          hasUpdate: isNewer,
          currentVersion: currentVersion,
          latestRelease: releaseInfo,
        );
      } else if (response.statusCode == 404) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          errorMessage: manualCheck
              ? 'أنت تستخدم أحدث إصدار، ولا توجد تحديثات جديدة بعد.'
              : null,
        );
      } else {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          errorMessage: manualCheck
              ? 'تعذر الوصول إلى خادم التحديثات (رمز الحالة: ${response.statusCode}).'
              : null,
        );
      }
    } on SocketException {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        errorMessage: manualCheck
            ? 'تعذر الاتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مجدداً.'
            : null,
      );
    } on TimeoutException {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        errorMessage: manualCheck
            ? 'استغرق الاتصال وقتاً طويلاً. يرجى المحاولة لاحقاً.'
            : null,
      );
    } catch (e) {
      debugPrint('Check update error: $e');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        errorMessage: manualCheck
            ? 'حدث خطأ أثناء فحص التحديثات. يرجى المحاولة لاحقاً.'
            : null,
      );
    }
  }

  /// Downloads the APK and triggers Android package installer.
  Stream<OtaEvent> downloadAndInstall({required String apkUrl}) {
    return OtaUpdate().execute(
      apkUrl,
      destinationFilename: 'AZKARY_update.apk',
    );
  }

  /// Compares two semver strings: e.g. "1.0.1" vs "1.0.0".
  /// Returns true if remoteVersion is strictly greater than currentVersion.
  static bool isVersionNewer(String currentVersion, String remoteVersion) {
    try {
      final currentParts = _parseVersion(currentVersion);
      final remoteParts = _parseVersion(remoteVersion);

      final maxLen = currentParts.length > remoteParts.length
          ? currentParts.length
          : remoteParts.length;

      for (int i = 0; i < maxLen; i++) {
        final currentVal = i < currentParts.length ? currentParts[i] : 0;
        final remoteVal = i < remoteParts.length ? remoteParts[i] : 0;

        if (remoteVal > currentVal) return true;
        if (remoteVal < currentVal) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static List<int> _parseVersion(String version) {
    final clean = version.replaceAll(RegExp(r'[^0-9.]'), '');
    return clean
        .split('.')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? 0)
        .toList();
  }
}
