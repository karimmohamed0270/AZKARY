import 'package:equatable/equatable.dart';
import '../../../core/services/location_service.dart';

abstract class PrayerTimesEvent extends Equatable {
  const PrayerTimesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPrayerTimesEvent extends PrayerTimesEvent {}

class UpdateRemainingTimerEvent extends PrayerTimesEvent {}

class ChangeCityEvent extends PrayerTimesEvent {
  final CityModel city;
  const ChangeCityEvent(this.city);

  @override
  List<Object?> get props => [city];
}

class FetchGpsLocationEvent extends PrayerTimesEvent {}

class UpdateCalculationMethodEvent extends PrayerTimesEvent {
  final String method;
  const UpdateCalculationMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class UpdateMadhabEvent extends PrayerTimesEvent {
  final String madhab;
  const UpdateMadhabEvent(this.madhab);

  @override
  List<Object?> get props => [madhab];
}
