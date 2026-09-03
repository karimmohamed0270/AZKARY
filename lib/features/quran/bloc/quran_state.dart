import 'package:equatable/equatable.dart';
import '../models/ayah_model.dart';
import '../models/surah_model.dart';

enum QuranStatus { initial, loading, loaded, error }

class QuranState extends Equatable {
  final QuranStatus status;
  final List<SurahModel> surahs;
  final List<SurahModel> filteredSurahs;
  final List<Map<String, dynamic>> searchedAyahs;
  final List<AyahModel> currentSurahAyahs;
  final SurahModel? currentSurah;
  final List<Map<String, dynamic>> bookmarks;
  final int lastReadSurahNumber;
  final String lastReadSurahName;
  final int lastReadAyahNumber;
  final double fontSize;
  final String? errorMessage;

  const QuranState({
    this.status = QuranStatus.initial,
    this.surahs = const [],
    this.filteredSurahs = const [],
    this.searchedAyahs = const [],
    this.currentSurahAyahs = const [],
    this.currentSurah,
    this.bookmarks = const [],
    this.lastReadSurahNumber = 1,
    this.lastReadSurahName = 'الفاتحة',
    this.lastReadAyahNumber = 1,
    this.fontSize = 22.0,
    this.errorMessage,
  });

  QuranState copyWith({
    QuranStatus? status,
    List<SurahModel>? surahs,
    List<SurahModel>? filteredSurahs,
    List<Map<String, dynamic>>? searchedAyahs,
    List<AyahModel>? currentSurahAyahs,
    SurahModel? currentSurah,
    List<Map<String, dynamic>>? bookmarks,
    int? lastReadSurahNumber,
    String? lastReadSurahName,
    int? lastReadAyahNumber,
    double? fontSize,
    String? errorMessage,
  }) {
    return QuranState(
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      filteredSurahs: filteredSurahs ?? this.filteredSurahs,
      searchedAyahs: searchedAyahs ?? this.searchedAyahs,
      currentSurahAyahs: currentSurahAyahs ?? this.currentSurahAyahs,
      currentSurah: currentSurah ?? this.currentSurah,
      bookmarks: bookmarks ?? this.bookmarks,
      lastReadSurahNumber: lastReadSurahNumber ?? this.lastReadSurahNumber,
      lastReadSurahName: lastReadSurahName ?? this.lastReadSurahName,
      lastReadAyahNumber: lastReadAyahNumber ?? this.lastReadAyahNumber,
      fontSize: fontSize ?? this.fontSize,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        surahs,
        filteredSurahs,
        searchedAyahs,
        currentSurahAyahs,
        currentSurah,
        bookmarks,
        lastReadSurahNumber,
        lastReadSurahName,
        lastReadAyahNumber,
        fontSize,
        errorMessage,
      ];
}
