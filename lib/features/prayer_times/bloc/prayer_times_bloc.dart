import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/preference_service.dart';
import '../data/prayer_calculator.dart';
import 'prayer_times_event.dart';
import 'prayer_times_state.dart';

class PrayerTimesBloc extends Bloc<PrayerTimesEvent, PrayerTimesState> {
  final LocationService locationService;
  final PreferenceService preferenceService;
  final NotificationService notificationService;
  Timer? _tickerTimer;

  PrayerTimesBloc({
    required this.locationService,
    required this.preferenceService,
    required this.notificationService,
  }) : super(const PrayerTimesState()) {
    on<LoadPrayerTimesEvent>(_onLoadPrayerTimes);
    on<UpdateRemainingTimerEvent>(_onUpdateRemainingTimer);
    on<ChangeCityEvent>(_onChangeCity);
    on<FetchGpsLocationEvent>(_onFetchGpsLocation);
    on<UpdateCalculationMethodEvent>(_onUpdateMethod);
    on<UpdateMadhabEvent>(_onUpdateMadhab);

    // Start 1-second ticker timer for real-time countdown
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(UpdateRemainingTimerEvent());
    });
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadPrayerTimes(
    LoadPrayerTimesEvent event,
    Emitter<PrayerTimesState> emit,
  ) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    try {
      final cities = await locationService.getOfflineCities();
      final lat = preferenceService.getLatitude();
      final lng = preferenceService.getLongitude();
      final cityName = preferenceService.getCityNameAr();
      final isGps = preferenceService.isGpsLocation();
      final method = preferenceService.getCalculationMethod();
      final madhab = preferenceService.getMadhab();

      final prayerTimes = PrayerCalculator.calculate(
        latitude: lat,
        longitude: lng,
        cityName: cityName,
        isGps: isGps,
        method: method,
        madhab: madhab,
      );

      final distance = locationService.calculateDistanceToKaaba(lat, lng);
      final qiblaAngle = locationService.calculateQiblaAngle(lat, lng);

      emit(state.copyWith(
        status: PrayerTimesStatus.loaded,
        prayerTimes: prayerTimes,
        availableCities: cities,
        selectedMethod: method,
        selectedMadhab: madhab,
        distanceToKaabaKm: distance,
        qiblaAngleDegrees: qiblaAngle,
      ));

      // Schedule offline notifications for the prayers
      _scheduleUpcomingNotifications(lat, lng, cityName, method, madhab);
    } catch (e) {
      emit(state.copyWith(
        status: PrayerTimesStatus.error,
        errorMessage: 'فشل حساب مواقيت الصلاة',
      ));
    }
  }

  void _onUpdateRemainingTimer(
    UpdateRemainingTimerEvent event,
    Emitter<PrayerTimesState> emit,
  ) {
    if (state.prayerTimes == null) return;

    final lat = preferenceService.getLatitude();
    final lng = preferenceService.getLongitude();
    final cityName = preferenceService.getCityNameAr();
    final isGps = preferenceService.isGpsLocation();
    final method = state.selectedMethod;
    final madhab = state.selectedMadhab;

    final updated = PrayerCalculator.calculate(
      latitude: lat,
      longitude: lng,
      cityName: cityName,
      isGps: isGps,
      method: method,
      madhab: madhab,
    );

    emit(state.copyWith(prayerTimes: updated));
  }

  Future<void> _onChangeCity(
    ChangeCityEvent event,
    Emitter<PrayerTimesState> emit,
  ) async {
    final city = event.city;
    await preferenceService.setLocation(
      cityNameAr: city.nameAr,
      cityNameEn: city.nameEn,
      latitude: city.lat,
      longitude: city.lng,
      isGps: false,
      method: city.method,
    );

    add(LoadPrayerTimesEvent());
  }

  Future<void> _onFetchGpsLocation(
    FetchGpsLocationEvent event,
    Emitter<PrayerTimesState> emit,
  ) async {
    final pos = await locationService.getCurrentGpsPosition();
    if (pos != null) {
      await preferenceService.setLocation(
        cityNameAr: 'موقعي الحالي (GPS)',
        cityNameEn: 'Current Location',
        latitude: pos.latitude,
        longitude: pos.longitude,
        isGps: true,
      );
      add(LoadPrayerTimesEvent());
    }
  }

  Future<void> _onUpdateMethod(
    UpdateCalculationMethodEvent event,
    Emitter<PrayerTimesState> emit,
  ) async {
    await preferenceService.setCalculationMethod(event.method);
    emit(state.copyWith(selectedMethod: event.method));
    add(LoadPrayerTimesEvent());
  }

  Future<void> _onUpdateMadhab(
    UpdateMadhabEvent event,
    Emitter<PrayerTimesState> emit,
  ) async {
    await preferenceService.setMadhab(event.madhab);
    emit(state.copyWith(selectedMadhab: event.madhab));
    add(LoadPrayerTimesEvent());
  }

  Future<void> _scheduleUpcomingNotifications(
    double lat,
    double lng,
    String cityName,
    String method,
    String madhab,
  ) async {
    if (!preferenceService.isAdhanNotificationEnabled()) return;

    try {
      await notificationService.cancelAllNotifications();

      // Schedule next 7 days of prayers
      int notifId = 1;
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final targetDate = now.add(Duration(days: i));
        final dayPrayers = PrayerCalculator.calculate(
          latitude: lat,
          longitude: lng,
          cityName: cityName,
          isGps: false,
          method: method,
          madhab: madhab,
          targetDate: targetDate,
        );

        final prayers = [
          {'name': 'الفجر', 'time': dayPrayers.fajr},
          {'name': 'الظهر', 'time': dayPrayers.dhuhr},
          {'name': 'العصر', 'time': dayPrayers.asr},
          {'name': 'المغرب', 'time': dayPrayers.maghrib},
          {'name': 'العشاء', 'time': dayPrayers.isha},
        ];

        for (final p in prayers) {
          final pTime = p['time'] as DateTime;
          final pName = p['name'] as String;
          if (pTime.isAfter(DateTime.now())) {
            await notificationService.schedulePrayerNotification(
              id: notifId++,
              title: 'حان الآن موعد أذان $pName',
              body: 'حي على الصلاة، حي على الفلاح ($cityName)',
              scheduledTime: pTime,
            );
          }
        }
      }

      // Schedule Morning (6:30 AM) & Evening (5:00 PM) Azkar
      if (preferenceService.isAzkarNotificationEnabled()) {
        await notificationService.scheduleDailyAzkarNotification(
          id: 9001,
          title: 'أذكار الصباح ☀️',
          body: 'أصبحنا وأصبح الملك لله.. ابدأ يومك بذكر الله وحفظه.',
          hour: 6,
          minute: 30,
        );

        await notificationService.scheduleDailyAzkarNotification(
          id: 9002,
          title: 'أذكار المساء 🌙',
          body: 'أمسينا وأمسى الملك لله.. حصّن نفسك بأذكار المساء.',
          hour: 17,
          minute: 0,
        );
      }
    } catch (_) {}
  }
}
