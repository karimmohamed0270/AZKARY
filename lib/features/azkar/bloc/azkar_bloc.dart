import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/audio_service.dart';
import '../data/azkar_repository.dart';
import 'azkar_event.dart';
import 'azkar_state.dart';

class AzkarBloc extends Bloc<AzkarEvent, AzkarState> {
  final AzkarRepository repository;
  final AudioService audioService;

  AzkarBloc({
    required this.repository,
    required this.audioService,
  }) : super(const AzkarState()) {
    on<LoadAzkarCategoriesEvent>(_onLoadCategories);
    on<LoadAzkarByCategoryEvent>(_onLoadByCategory);
    on<DecrementZikrCountEvent>(_onDecrementCount);
    on<ResetZikrProgressEvent>(_onResetProgress);
    on<LoadAsmaaAllahEvent>(_onLoadAsmaaAllah);
  }

  Future<void> _onLoadCategories(
    LoadAzkarCategoriesEvent event,
    Emitter<AzkarState> emit,
  ) async {
    emit(state.copyWith(status: AzkarStatus.loading));
    try {
      final categories = await repository.getCategories();
      final asmaa = await repository.getAsmaaAllah();
      emit(state.copyWith(
        status: AzkarStatus.loaded,
        categories: categories,
        asmaaAllah: asmaa,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AzkarStatus.error,
        errorMessage: 'فشل تحميل أقسام الأذكار',
      ));
    }
  }

  Future<void> _onLoadByCategory(
    LoadAzkarByCategoryEvent event,
    Emitter<AzkarState> emit,
  ) async {
    try {
      final azkar = await repository.getAzkarByCategory(event.category);
      final Map<int, int> counts = {};
      for (final z in azkar) {
        counts[z.id] = z.count;
      }

      emit(state.copyWith(
        selectedCategory: event.category,
        currentCategoryAzkar: azkar,
        zikrRemainingCounts: counts,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'فشل تحميل الأذكار'));
    }
  }

  Future<void> _onDecrementCount(
    DecrementZikrCountEvent event,
    Emitter<AzkarState> emit,
  ) async {
    final counts = Map<int, int>.from(state.zikrRemainingCounts);
    final current = counts[event.zikrId] ?? 1;

    if (current > 0) {
      final updated = current - 1;
      counts[event.zikrId] = updated;

      if (updated == 0) {
        // Double buzz / heavy haptic on completion
        await audioService.completionFeedback();
      } else {
        // Light tap haptic
        await audioService.clickFeedback();
      }

      emit(state.copyWith(zikrRemainingCounts: counts));
    }
  }

  Future<void> _onResetProgress(
    ResetZikrProgressEvent event,
    Emitter<AzkarState> emit,
  ) async {
    final azkar = state.currentCategoryAzkar;
    final Map<int, int> counts = {};
    for (final z in azkar) {
      counts[z.id] = z.count;
    }
    emit(state.copyWith(zikrRemainingCounts: counts));
  }

  Future<void> _onLoadAsmaaAllah(
    LoadAsmaaAllahEvent event,
    Emitter<AzkarState> emit,
  ) async {
    try {
      final asmaa = await repository.getAsmaaAllah();
      emit(state.copyWith(asmaaAllah: asmaa));
    } catch (_) {}
  }
}
