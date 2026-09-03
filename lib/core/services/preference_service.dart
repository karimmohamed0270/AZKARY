import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyCalcMethod = 'calc_method';
  static const String _keyMadhab = 'madhab';
  static const String _keyCityNameAr = 'city_name_ar';
  static const String _keyCityNameEn = 'city_name_en';
  static const String _keyLatitude = 'latitude';
  static const String _keyLongitude = 'longitude';
  static const String _keyIsGpsLocation = 'is_gps_location';

  // Quran Bookmarks & Last Read
  static const String _keyLastReadSurah = 'last_read_surah';
  static const String _keyLastReadSurahName = 'last_read_surah_name';
  static const String _keyLastReadAyah = 'last_read_ayah';
  static const String _keyBookmarks = 'quran_bookmarks';
  static const String _keyQuranFontSize = 'quran_font_size';

  // Tasbeeh
  static const String _keyTasbeehTotal = 'tasbeeh_total_count';
  static const String _keyTasbeehSound = 'tasbeeh_sound_enabled';
  static const String _keyTasbeehHaptic = 'tasbeeh_haptic_enabled';

  // Notifications
  static const String _keyAdhanNotifications = 'adhan_notifications_enabled';
  static const String _keyAzkarNotifications = 'azkar_notifications_enabled';

  // --- Theme Mode ---
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  // --- Calculation Method & Madhab ---
  String getCalculationMethod() => _prefs.getString(_keyCalcMethod) ?? 'egyptian';
  Future<void> setCalculationMethod(String method) => _prefs.setString(_keyCalcMethod, method);

  String getMadhab() => _prefs.getString(_keyMadhab) ?? 'shafi';
  Future<void> setMadhab(String madhab) => _prefs.setString(_keyMadhab, madhab);

  // --- Location & City ---
  String getCityNameAr() => _prefs.getString(_keyCityNameAr) ?? 'القاهرة';
  String getCityNameEn() => _prefs.getString(_keyCityNameEn) ?? 'Cairo';
  double getLatitude() => _prefs.getDouble(_keyLatitude) ?? 30.0444;
  double getLongitude() => _prefs.getDouble(_keyLongitude) ?? 31.2357;
  bool isGpsLocation() => _prefs.getBool(_keyIsGpsLocation) ?? false;

  Future<void> setLocation({
    required String cityNameAr,
    required String cityNameEn,
    required double latitude,
    required double longitude,
    required bool isGps,
    String? method,
  }) async {
    await _prefs.setString(_keyCityNameAr, cityNameAr);
    await _prefs.setString(_keyCityNameEn, cityNameEn);
    await _prefs.setDouble(_keyLatitude, latitude);
    await _prefs.setDouble(_keyLongitude, longitude);
    await _prefs.setBool(_keyIsGpsLocation, isGps);
    if (method != null) {
      await _prefs.setString(_keyCalcMethod, method);
    }
  }

  // --- Quran Last Read ---
  int getLastReadSurah() => _prefs.getInt(_keyLastReadSurah) ?? 1;
  String getLastReadSurahName() => _prefs.getString(_keyLastReadSurahName) ?? 'الفاتحة';
  int getLastReadAyah() => _prefs.getInt(_keyLastReadAyah) ?? 1;

  Future<void> setLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    await _prefs.setInt(_keyLastReadSurah, surahNumber);
    await _prefs.setString(_keyLastReadSurahName, surahName);
    await _prefs.setInt(_keyLastReadAyah, ayahNumber);
  }

  // --- Quran Bookmarks ---
  List<Map<String, dynamic>> getBookmarks() {
    final str = _prefs.getString(_keyBookmarks);
    if (str == null || str.isEmpty) return [];
    try {
      final list = json.decode(str) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    required String ayahText,
  }) async {
    final bookmarks = getBookmarks();
    final exists = bookmarks.any(
      (b) => b['surah_number'] == surahNumber && b['ayah_number'] == ayahNumber,
    );
    if (!exists) {
      bookmarks.insert(0, {
        'surah_number': surahNumber,
        'surah_name': surahName,
        'ayah_number': ayahNumber,
        'ayah_text': ayahText,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _prefs.setString(_keyBookmarks, json.encode(bookmarks));
    }
  }

  Future<void> removeBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final bookmarks = getBookmarks();
    bookmarks.removeWhere(
      (b) => b['surah_number'] == surahNumber && b['ayah_number'] == ayahNumber,
    );
    await _prefs.setString(_keyBookmarks, json.encode(bookmarks));
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    final bookmarks = getBookmarks();
    return bookmarks.any(
      (b) => b['surah_number'] == surahNumber && b['ayah_number'] == ayahNumber,
    );
  }

  // --- Quran Font Size ---
  double getQuranFontSize() => _prefs.getDouble(_keyQuranFontSize) ?? 22.0;
  Future<void> setQuranFontSize(double size) => _prefs.setDouble(_keyQuranFontSize, size);

  // --- Tasbeeh ---
  int getTasbeehTotal() => _prefs.getInt(_keyTasbeehTotal) ?? 0;
  Future<void> incrementTasbeehTotal() async {
    final current = getTasbeehTotal();
    await _prefs.setInt(_keyTasbeehTotal, current + 1);
  }

  Future<void> resetTasbeehTotal() => _prefs.setInt(_keyTasbeehTotal, 0);

  bool isTasbeehSoundEnabled() => _prefs.getBool(_keyTasbeehSound) ?? true;
  Future<void> setTasbeehSound(bool enabled) => _prefs.setBool(_keyTasbeehSound, enabled);

  bool isTasbeehHapticEnabled() => _prefs.getBool(_keyTasbeehHaptic) ?? true;
  Future<void> setTasbeehHaptic(bool enabled) => _prefs.setBool(_keyTasbeehHaptic, enabled);

  // --- Notifications ---
  bool isAdhanNotificationEnabled() => _prefs.getBool(_keyAdhanNotifications) ?? true;
  Future<void> setAdhanNotification(bool enabled) => _prefs.setBool(_keyAdhanNotifications, enabled);

  bool isAzkarNotificationEnabled() => _prefs.getBool(_keyAzkarNotifications) ?? true;
  Future<void> setAzkarNotification(bool enabled) => _prefs.setBool(_keyAzkarNotifications, enabled);
}
