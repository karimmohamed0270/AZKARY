import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/preference_service.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../bloc/prayer_times_bloc.dart';
import '../../bloc/prayer_times_state.dart';
import '../../data/prayer_calculator.dart';
import '../../models/prayer_times_model.dart';

class PrayerSchedulePage extends StatelessWidget {
  const PrayerSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      builder: (context, state) {
        final cityName = state.prayerTimes?.cityName ?? 'القاهرة';
        final prefService = RepositoryProvider.of<PreferenceService>(context);
        final lat = prefService.getLatitude();
        final lng = prefService.getLongitude();
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        return Scaffold(
          appBar: AppBar(
            title: Text('مواقيت الصلاة الشهرية ($cityName)'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: daysInMonth,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final dayDate = DateTime(now.year, now.month, index + 1);
              final isToday = dayDate.day == now.day;

              final dayPrayers = PrayerCalculator.calculate(
                latitude: lat,
                longitude: lng,
                cityName: cityName,
                isGps: state.prayerTimes?.isGps ?? false,
                method: state.selectedMethod,
                madhab: state.selectedMadhab,
                fajrAdjustment: state.fajrAdjustment,
                sunriseAdjustment: state.sunriseAdjustment,
                dhuhrAdjustment: state.dhuhrAdjustment,
                asrAdjustment: state.asrAdjustment,
                maghribAdjustment: state.maghribAdjustment,
                ishaAdjustment: state.ishaAdjustment,
                targetDate: dayDate,
              );

              final hijri = HijriHelper.getHijriCalendar(dayDate);

              return Card(
                color: isToday ? AppColors.primaryContainer.withOpacity(0.5) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isToday ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${dayDate.day}/${dayDate.month} • ${ArabicNumbers.convert(hijri.hDay)} ${HijriHelper.arabicMonths[hijri.hMonth - 1]}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isToday ? AppColors.primary : null,
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'اليوم',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeColumn('الفجر', dayPrayers.fajr),
                          _buildTimeColumn('الشروق', dayPrayers.sunrise),
                          _buildTimeColumn('الظهر', dayPrayers.dhuhr),
                          _buildTimeColumn('العصر', dayPrayers.asr),
                          _buildTimeColumn('المغرب', dayPrayers.maghrib),
                          _buildTimeColumn('العشاء', dayPrayers.isha),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeColumn(String name, DateTime time) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          ArabicNumbers.formatTime12h(time).split(' ')[0],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
