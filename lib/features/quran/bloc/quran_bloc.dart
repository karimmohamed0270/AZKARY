import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/preference_service.dart';
import '../data/quran_repository.dart';
import 'quran_event.dart';
import 'quran_state.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranRepository repository;
  final PreferenceService preferenceService;

  QuranBloc({
    required this.repository,
    required this.preferenceService,
  }) : super(const QuranState()) {
    on<LoadQuranSurahsEvent>(_onLoadSurahs);
    on<SearchQuranEvent>(_onSearchQuran);
    on<LoadSurahDetailEvent>(_onLoadSurahDetail);
    on<ToggleBookmarkEvent>(_onToggleBookmark);
    on<SaveLastReadEvent>(_onSaveLastRead);
    on<ChangeFontSizeEvent>(_onChangeFontSize);
  }

  Future<void> _onLoadSurahs(
    LoadQuranSurahsEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(state.copyWith(status: QuranStatus.loading));
    try {
      final surahs = await repository.getSurahs();
      final bookmarks = preferenceService.getBookmarks();
      final lastReadSurah = preferenceService.getLastReadSurah();
      final lastReadName = preferenceService.getLastReadSurahName();
      final lastReadAyah = preferenceService.getLastReadAyah();
      final fontSize = preferenceService.getQuranFontSize();

      emit(state.copyWith(
        status: QuranStatus.loaded,
        surahs: surahs,
        filteredSurahs: surahs,
        bookmarks: bookmarks,
        lastReadSurahNumber: lastReadSurah,
        lastReadSurahName: lastReadName,
        lastReadAyahNumber: lastReadAyah,
        fontSize: fontSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: QuranStatus.error,
        errorMessage: 'فشل تحميل بيانات القرآن الكريم',
      ));
    }
  }

  Future<void> _onSearchQuran(
    SearchQuranEvent event,
    Emitter<QuranState> emit,
  ) async {
    final query = event.query;
    if (query.trim().isEmpty) {
      emit(state.copyWith(
        filteredSurahs: state.surahs,
        searchedAyahs: const [],
      ));
      return;
    }

    final filteredSurahs = await repository.searchSurahs(query);
    final searchedAyahs = await repository.searchAyahs(query);

    emit(state.copyWith(
      filteredSurahs: filteredSurahs,
      searchedAyahs: searchedAyahs,
    ));
  }

  Future<void> _onLoadSurahDetail(
    LoadSurahDetailEvent event,
    Emitter<QuranState> emit,
  ) async {
    try {
      final surah = await repository.getSurahByNumber(event.surahNumber);
      final ayahs = await repository.getSurahAyahs(event.surahNumber);

      emit(state.copyWith(
        currentSurah: surah,
        currentSurahAyahs: ayahs,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'فشل تحميل آيات السورة',
      ));
    }
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkEvent event,
    Emitter<QuranState> emit,
  ) async {
    final isAlready = preferenceService.isBookmarked(event.surahNumber, event.ayahNumber);
    if (isAlready) {
      await preferenceService.removeBookmark(
        surahNumber: event.surahNumber,
        ayahNumber: event.ayahNumber,
      );
    } else {
      await preferenceService.addBookmark(
        surahNumber: event.surahNumber,
        surahName: event.surahName,
        ayahNumber: event.ayahNumber,
        ayahText: event.ayahText,
      );
    }
    final updatedBookmarks = preferenceService.getBookmarks();
    emit(state.copyWith(bookmarks: updatedBookmarks));
  }

  Future<void> _onSaveLastRead(
    SaveLastReadEvent event,
    Emitter<QuranState> emit,
  ) async {
    await preferenceService.setLastRead(
      surahNumber: event.surahNumber,
      surahName: event.surahName,
      ayahNumber: event.ayahNumber,
    );
    emit(state.copyWith(
      lastReadSurahNumber: event.surahNumber,
      lastReadSurahName: event.surahName,
      lastReadAyahNumber: event.ayahNumber,
    ));
  }

  Future<void> _onChangeFontSize(
    ChangeFontSizeEvent event,
    Emitter<QuranState> emit,
  ) async {
    await preferenceService.setQuranFontSize(event.fontSize);
    emit(state.copyWith(fontSize: event.fontSize));
  }
}
