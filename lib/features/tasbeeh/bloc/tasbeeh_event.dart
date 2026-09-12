import 'package:equatable/equatable.dart';

abstract class TasbeehEvent extends Equatable {
  const TasbeehEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasbeehEvent extends TasbeehEvent {}

class IncrementTasbeehEvent extends TasbeehEvent {}

class ResetCurrentCounterEvent extends TasbeehEvent {}

class ResetTotalCounterEvent extends TasbeehEvent {}

class SetTargetCountEvent extends TasbeehEvent {
  final int target;
  const SetTargetCountEvent(this.target);

  @override
  List<Object?> get props => [target];
}

class SelectDhikrEvent extends TasbeehEvent {
  final String dhikr;
  const SelectDhikrEvent(this.dhikr);

  @override
  List<Object?> get props => [dhikr];
}

class ToggleSoundEvent extends TasbeehEvent {}

class ToggleHapticEvent extends TasbeehEvent {}

class SetDailyGoalEvent extends TasbeehEvent {
  final int goal;
  const SetDailyGoalEvent(this.goal);

  @override
  List<Object?> get props => [goal];
}
