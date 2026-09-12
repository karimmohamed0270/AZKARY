import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/preference_service.dart';
import 'tasbeeh_event.dart';
import 'tasbeeh_state.dart';

class TasbeehBloc extends Bloc<TasbeehEvent, TasbeehState> {
  final PreferenceService preferenceService;
  final AudioService audioService;

  TasbeehBloc({
    required this.preferenceService,
    required this.audioService,
  }) : super(const TasbeehState()) {
    on<LoadTasbeehEvent>(_onLoadTasbeeh);
    on<IncrementTasbeehEvent>(_onIncrementTasbeeh);
    on<ResetCurrentCounterEvent>(_onResetCurrent);
    on<ResetTotalCounterEvent>(_onResetTotal);
    on<SetTargetCountEvent>(_onSetTarget);
    on<SelectDhikrEvent>(_onSelectDhikr);
    on<ToggleSoundEvent>(_onToggleSound);
    on<ToggleHapticEvent>(_onToggleHaptic);
    on<SetDailyGoalEvent>(_onSetDailyGoal);
  }

  void _onLoadTasbeeh(LoadTasbeehEvent event, Emitter<TasbeehState> emit) {
    final total = preferenceService.getTasbeehTotal();
    final sound = preferenceService.isTasbeehSoundEnabled();
    final haptic = preferenceService.isTasbeehHapticEnabled();
    final today = preferenceService.getTodayTasbeehCount();
    final goal = preferenceService.getTasbeehDailyGoal();
    final streak = preferenceService.getTasbeehStreak();
    final history = preferenceService.getTasbeehDailyHistory();

    emit(state.copyWith(
      totalLifetimeCount: total,
      isSoundEnabled: sound,
      isHapticEnabled: haptic,
      todayCount: today,
      dailyGoal: goal,
      streakDays: streak,
      dailyHistory: history,
    ));
  }

  Future<void> _onIncrementTasbeeh(
    IncrementTasbeehEvent event,
    Emitter<TasbeehState> emit,
  ) async {
    final newCount = state.currentCount + 1;
    final newTotal = state.totalLifetimeCount + 1;
    await preferenceService.incrementTasbeehTotal();
    final newToday = await preferenceService.incrementTodayTasbeeh();
    final newStreak = preferenceService.getTasbeehStreak();
    final updatedHistory = preferenceService.getTasbeehDailyHistory();

    int newCycle = state.currentCycle;
    int displayCount = newCount;

    // Check if target reached
    if (state.targetCount > 0 && newCount >= state.targetCount) {
      newCycle += 1;
      displayCount = 0; // Reset for next cycle

      if (state.isHapticEnabled) {
        await audioService.completionFeedback();
      }
    } else {
      if (state.isHapticEnabled) {
        await audioService.clickFeedback();
      }
    }

    emit(state.copyWith(
      currentCount: displayCount,
      currentCycle: newCycle,
      totalLifetimeCount: newTotal,
      todayCount: newToday,
      streakDays: newStreak,
      dailyHistory: updatedHistory,
    ));
  }

  void _onResetCurrent(ResetCurrentCounterEvent event, Emitter<TasbeehState> emit) {
    emit(state.copyWith(currentCount: 0));
  }

  Future<void> _onResetTotal(ResetTotalCounterEvent event, Emitter<TasbeehState> emit) async {
    await preferenceService.resetTasbeehTotal();
    emit(state.copyWith(currentCount: 0, currentCycle: 0, totalLifetimeCount: 0));
  }

  void _onSetTarget(SetTargetCountEvent event, Emitter<TasbeehState> emit) {
    emit(state.copyWith(targetCount: event.target, currentCount: 0, currentCycle: 0));
  }

  void _onSelectDhikr(SelectDhikrEvent event, Emitter<TasbeehState> emit) {
    emit(state.copyWith(selectedDhikr: event.dhikr, currentCount: 0));
  }

  Future<void> _onToggleSound(ToggleSoundEvent event, Emitter<TasbeehState> emit) async {
    final updated = !state.isSoundEnabled;
    await preferenceService.setTasbeehSound(updated);
    emit(state.copyWith(isSoundEnabled: updated));
  }

  Future<void> _onToggleHaptic(ToggleHapticEvent event, Emitter<TasbeehState> emit) async {
    final updated = !state.isHapticEnabled;
    await preferenceService.setTasbeehHaptic(updated);
    emit(state.copyWith(isHapticEnabled: updated));
  }

  Future<void> _onSetDailyGoal(SetDailyGoalEvent event, Emitter<TasbeehState> emit) async {
    await preferenceService.setTasbeehDailyGoal(event.goal);
    emit(state.copyWith(dailyGoal: event.goal));
  }
}
