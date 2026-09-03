import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/preference_service.dart';
import '../../features/azkar/bloc/azkar_bloc.dart';
import '../../features/azkar/data/azkar_repository.dart';
import '../../features/prayer_times/bloc/prayer_times_bloc.dart';
import '../../features/quran/bloc/quran_bloc.dart';
import '../../features/quran/data/quran_repository.dart';
import '../../features/tasbeeh/bloc/tasbeeh_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 1. SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 2. Core Services
  getIt.registerLazySingleton<PreferenceService>(() => PreferenceService(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<AudioService>(() => AudioService());

  // 3. Repositories
  getIt.registerLazySingleton<QuranRepository>(() => QuranRepository());
  getIt.registerLazySingleton<AzkarRepository>(() => AzkarRepository());

  // 4. BLoCs
  getIt.registerFactory<QuranBloc>(() => QuranBloc(
        repository: getIt<QuranRepository>(),
        preferenceService: getIt<PreferenceService>(),
      ));

  getIt.registerFactory<PrayerTimesBloc>(() => PrayerTimesBloc(
        locationService: getIt<LocationService>(),
        preferenceService: getIt<PreferenceService>(),
        notificationService: getIt<NotificationService>(),
      ));

  getIt.registerFactory<AzkarBloc>(() => AzkarBloc(
        repository: getIt<AzkarRepository>(),
        audioService: getIt<AudioService>(),
      ));

  getIt.registerFactory<TasbeehBloc>(() => TasbeehBloc(
        preferenceService: getIt<PreferenceService>(),
        audioService: getIt<AudioService>(),
      ));
}
