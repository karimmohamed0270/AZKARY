import 'package:equatable/equatable.dart';

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuranSurahsEvent extends QuranEvent {}

class SearchQuranEvent extends QuranEvent {
  final String query;
  const SearchQuranEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadSurahDetailEvent extends QuranEvent {
  final int surahNumber;
  const LoadSurahDetailEvent(this.surahNumber);

  @override
  List<Object?> get props => [surahNumber];
}

class ToggleBookmarkEvent extends QuranEvent {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;

  const ToggleBookmarkEvent({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  List<Object?> get props => [surahNumber, surahName, ayahNumber, ayahText];
}

class SaveLastReadEvent extends QuranEvent {
  final int surahNumber;
  final String surahName;
  final int ayahNumber;

  const SaveLastReadEvent({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
  });

  @override
  List<Object?> get props => [surahNumber, surahName, ayahNumber];
}

class ChangeFontSizeEvent extends QuranEvent {
  final double fontSize;
  const ChangeFontSizeEvent(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}
