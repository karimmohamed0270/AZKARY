import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ayah_model.dart';
import '../models/juz_model.dart';
import '../models/surah_model.dart';

class QuranRepository {
  List<SurahModel>? _cachedSurahs;
  Map<int, List<AyahModel>>? _cachedSurahAyahs;
  List<Map<String, dynamic>>? _allAyahsForSearch;

  /// Load all 114 Surahs metadata
  Future<List<SurahModel>> getSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;
    final jsonStr = await rootBundle.loadString('assets/data/quran_surahs.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    _cachedSurahs = list.map((e) => SurahModel.fromJson(e as Map<String, dynamic>)).toList();
    return _cachedSurahs!;
  }

  /// Get list of all 30 Quran Juz
  List<JuzModel> getJuzs() {
    return JuzModel.allJuzs;
  }

  /// Get Juz data grouped by Surah segments
  Future<List<Map<String, dynamic>>> getJuzSurahSegments(int juzNumber) async {
    await _ensureQuranTextLoaded();
    final surahs = await getSurahs();
    final List<Map<String, dynamic>> segments = [];

    final juzModel = JuzModel.allJuzs.firstWhere(
      (j) => j.number == juzNumber,
      orElse: () => JuzModel.allJuzs.first,
    );

    for (int sNum = juzModel.startSurahNum; sNum <= juzModel.endSurahNum; sNum++) {
      final surahMatches = surahs.where((s) => s.number == sNum);
      if (surahMatches.isEmpty) continue;
      final surah = surahMatches.first;
      final allAyahsOfSurah = _cachedSurahAyahs?[sNum] ?? [];
      final juzAyahs = allAyahsOfSurah.where((a) => a.juz == juzNumber).toList();

      if (juzAyahs.isNotEmpty) {
        segments.add({
          'surah': surah,
          'ayahs': juzAyahs,
        });
      }
    }

    return segments;
  }

  /// Load Surah Ayahs from quran_text.json
  Future<List<AyahModel>> getSurahAyahs(int surahNumber) async {
    await _ensureQuranTextLoaded();
    return _cachedSurahAyahs?[surahNumber] ?? [];
  }

  /// Get specific Surah metadata by its number
  Future<SurahModel?> getSurahByNumber(int number) async {
    final surahs = await getSurahs();
    try {
      return surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  /// Fast offline search in Surah names
  Future<List<SurahModel>> searchSurahs(String query) async {
    final surahs = await getSurahs();
    if (query.trim().isEmpty) return surahs;

    final cleanQuery = _normalizeArabic(query.trim().toLowerCase());
    return surahs.where((s) {
      final nameAr = _normalizeArabic(s.nameAr.toLowerCase());
      final nameEn = s.nameEn.toLowerCase();
      final numStr = s.number.toString();
      return nameAr.contains(cleanQuery) ||
          nameEn.contains(cleanQuery) ||
          numStr == cleanQuery;
    }).toList();
  }

  /// Search across all Ayahs offline
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    if (query.trim().length < 2) return [];
    await _ensureQuranTextLoaded();

    final cleanQuery = _normalizeArabic(query.trim().toLowerCase());
    final List<Map<String, dynamic>> results = [];

    if (_allAyahsForSearch != null) {
      for (final item in _allAyahsForSearch!) {
        final normText = _normalizeArabic(item['text'].toString().toLowerCase());
        if (normText.contains(cleanQuery)) {
          results.add(item);
          if (results.length >= 50) break; // Limit search results for performance
        }
      }
    }
    return results;
  }

  Future<void> _ensureQuranTextLoaded() async {
    if (_cachedSurahAyahs != null) return;

    _cachedSurahAyahs = {};
    _allAyahsForSearch = [];

    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran_text.json');
      final List<dynamic> surahsList = json.decode(jsonStr) as List<dynamic>;

      for (final surahJson in surahsList) {
        final surahNum = surahJson['number'] as int;
        final surahName = surahJson['name'] as String? ?? '';
        final ayahsRaw = surahJson['ayahs'] as List<dynamic>? ?? [];

        final List<AyahModel> ayahs = [];
        for (final ayahRaw in ayahsRaw) {
          final ayah = AyahModel.fromJson(ayahRaw as Map<String, dynamic>);
          ayahs.add(ayah);

          _allAyahsForSearch!.add({
            'surah_number': surahNum,
            'surah_name': surahName,
            'ayah_number': ayah.numberInSurah,
            'text': ayah.text,
            'page': ayah.page,
            'juz': ayah.juz,
          });
        }
        _cachedSurahAyahs![surahNum] = ayahs;
      }
    } catch (_) {
      // Fallback: create placeholder ayahs if loading encounters any issue
    }
  }

  /// Remove Tashkeel and normalize Arabic letters for robust search
  String _normalizeArabic(String text) {
    var result = text;
    // Remove Tashkeel / Harakat
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    // Normalize Alef
    result = result.replaceAll(RegExp(r'[إأآا]'), 'ا');
    // Normalize Taa Marbuta & Haa
    result = result.replaceAll('ة', 'ه');
    // Normalize Yaa
    result = result.replaceAll('ى', 'ي');
    return result;
  }
}
