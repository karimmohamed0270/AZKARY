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

class UpdatePrayerAdjustmentsEvent extends PrayerTimesEvent {
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const UpdatePrayerAdjustmentsEvent({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  @override
  List<Object?> get props => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}

class ResetPrayerAdjustmentsEvent extends PrayerTimesEvent {}

