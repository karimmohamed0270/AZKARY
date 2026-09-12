import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/services/preference_service.dart';
import 'core/theme/app_theme.dart';
import 'features/azkar/bloc/azkar_bloc.dart';
import 'features/azkar/bloc/azkar_event.dart';
import 'features/main/presentation/pages/main_navigation_page.dart';
import 'features/prayer_times/bloc/prayer_times_bloc.dart';
import 'features/prayer_times/bloc/prayer_times_event.dart';
import 'features/quran/bloc/quran_bloc.dart';
import 'features/quran/bloc/quran_event.dart';
import 'features/tasbeeh/bloc/tasbeeh_bloc.dart';
import 'features/tasbeeh/bloc/tasbeeh_event.dart';

class AzkariApp extends StatefulWidget {
  const AzkariApp({super.key});

  @override
  State<AzkariApp> createState() => _AzkariAppState();
}

class _AzkariAppState extends State<AzkariApp> {
  late String _themeModeStr;

  @override
  void initState() {
    super.initState();
    _themeModeStr = getIt<PreferenceService>().getThemeMode();
  }

  ThemeMode _getThemeMode() {
    switch (_themeModeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _onThemeChanged(String newMode) {
    setState(() {
      _themeModeStr = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PreferenceService>.value(
          value: getIt<PreferenceService>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<QuranBloc>(
            create: (_) => getIt<QuranBloc>()..add(LoadQuranSurahsEvent()),
          ),
          BlocProvider<PrayerTimesBloc>(
            create: (_) =>
                getIt<PrayerTimesBloc>()..add(LoadPrayerTimesEvent()),
          ),
          BlocProvider<AzkarBloc>(
            create: (_) => getIt<AzkarBloc>()..add(LoadAzkarCategoriesEvent()),
          ),
          BlocProvider<TasbeehBloc>(
            create: (_) => getIt<TasbeehBloc>()..add(LoadTasbeehEvent()),
          ),
        ],
        child: MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MainNavigationPage(onThemeChanged: _onThemeChanged),
        ),
      ),
    );
  }
}
