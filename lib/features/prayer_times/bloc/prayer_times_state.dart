import 'package:equatable/equatable.dart';
import '../../../core/services/location_service.dart';
import '../models/prayer_times_model.dart';

enum PrayerTimesStatus { initial, loading, loaded, error }

class PrayerTimesState extends Equatable {
  final PrayerTimesStatus status;
  final PrayerTimesModel? prayerTimes;
  final List<CityModel> availableCities;
  final String selectedMethod;
  final String selectedMadhab;
  final double distanceToKaabaKm;
  final double qiblaAngleDegrees;
  final String? errorMessage;
  final int fajrAdjustment;
  final int sunriseAdjustment;
  final int dhuhrAdjustment;
  final int asrAdjustment;
  final int maghribAdjustment;
  final int ishaAdjustment;

  const PrayerTimesState({
    this.status = PrayerTimesStatus.initial,
    this.prayerTimes,
    this.availableCities = const [],
    this.selectedMethod = 'egyptian',
    this.selectedMadhab = 'shafi',
    this.distanceToKaabaKm = 0.0,
    this.qiblaAngleDegrees = 0.0,
    this.errorMessage,
    this.fajrAdjustment = 0,
    this.sunriseAdjustment = 0,
    this.dhuhrAdjustment = 0,
    this.asrAdjustment = 0,
    this.maghribAdjustment = 0,
    this.ishaAdjustment = 0,
  });

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    PrayerTimesModel? prayerTimes,
    List<CityModel>? availableCities,
    String? selectedMethod,
    String? selectedMadhab,
    double? distanceToKaabaKm,
    double? qiblaAngleDegrees,
    String? errorMessage,
    int? fajrAdjustment,
    int? sunriseAdjustment,
    int? dhuhrAdjustment,
    int? asrAdjustment,
    int? maghribAdjustment,
    int? ishaAdjustment,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      availableCities: availableCities ?? this.availableCities,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      selectedMadhab: selectedMadhab ?? this.selectedMadhab,
      distanceToKaabaKm: distanceToKaabaKm ?? this.distanceToKaabaKm,
      qiblaAngleDegrees: qiblaAngleDegrees ?? this.qiblaAngleDegrees,
      errorMessage: errorMessage ?? this.errorMessage,
      fajrAdjustment: fajrAdjustment ?? this.fajrAdjustment,
      sunriseAdjustment: sunriseAdjustment ?? this.sunriseAdjustment,
      dhuhrAdjustment: dhuhrAdjustment ?? this.dhuhrAdjustment,
      asrAdjustment: asrAdjustment ?? this.asrAdjustment,
      maghribAdjustment: maghribAdjustment ?? this.maghribAdjustment,
      ishaAdjustment: ishaAdjustment ?? this.ishaAdjustment,
    );
  }

  @override
  List<Object?> get props => [
        status,
        prayerTimes,
        availableCities,
        selectedMethod,
        selectedMadhab,
        distanceToKaabaKm,
        qiblaAngleDegrees,
        errorMessage,
        fajrAdjustment,
        sunriseAdjustment,
        dhuhrAdjustment,
        asrAdjustment,
        maghribAdjustment,
        ishaAdjustment,
      ];
}

