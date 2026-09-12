import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../azkar/presentation/pages/asmaa_allah_page.dart';
import '../../../azkar/presentation/pages/zikr_reading_page.dart';
import '../../../azkar/bloc/azkar_bloc.dart';
import '../../../azkar/bloc/azkar_event.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../prayer_times/bloc/prayer_times_bloc.dart';
import '../../../prayer_times/bloc/prayer_times_event.dart';
import '../../../prayer_times/bloc/prayer_times_state.dart';
import '../../../prayer_times/presentation/pages/prayer_schedule_page.dart';
import '../../../prayer_times/presentation/widgets/next_prayer_card.dart';
import '../../../prayer_times/presentation/widgets/prayer_row_item.dart';
import '../../../quran/presentation/pages/surah_detail_page.dart';
import '../../../quran/bloc/quran_bloc.dart';
import '../../../quran/bloc/quran_state.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomePage({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fastingReminder = HijriHelper.getFastingReminder();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            tooltip: AppStrings.hijriCalendar,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<PrayerTimesBloc>().add(LoadPrayerTimesEvent());
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Fasting Reminder Banner (if today is a fasting day)
            if (fastingReminder != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldDark.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.black87, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fastingReminder,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Next Prayer Card Hero
            BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
              builder: (context, state) {
                if (state.status == PrayerTimesStatus.loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final prayerTimes = state.prayerTimes;
                if (prayerTimes == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    NextPrayerCard(prayerTimes: prayerTimes),
                    const SizedBox(height: 16),

                    // Daily Prayer Times Accordion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.prayerTimes,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          icon: const Icon(Icons.table_chart_outlined, size: 18),
                          label: const Text('جدول الشهر'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrayerSchedulePage()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    PrayerRowItem(
                      prayerName: AppStrings.fajr,
                      prayerTime: prayerTimes.fajr,
                      isNext: prayerTimes.nextPrayerName == 'الفجر',
                      iconData: Icons.wb_twilight,
                    ),
                    PrayerRowItem(
                      prayerName: AppStrings.sunrise,
                      prayerTime: prayerTimes.sunrise,
                      isNext: prayerTimes.nextPrayerName == 'الشروق',
                      iconData: Icons.wb_sunny_outlined,
                    ),
                    PrayerRowItem(
                      prayerName: AppStrings.dhuhr,
                      prayerTime: prayerTimes.dhuhr,
                      isNext: prayerTimes.nextPrayerName == 'الظهر',
                      iconData: Icons.wb_sunny,
                    ),
                    PrayerRowItem(
                      prayerName: AppStrings.asr,
                      prayerTime: prayerTimes.asr,
                      isNext: prayerTimes.nextPrayerName == 'العصر',
                      iconData: Icons.filter_drama,
                    ),
                    PrayerRowItem(
                      prayerName: AppStrings.maghrib,
                      prayerTime: prayerTimes.maghrib,
                      isNext: prayerTimes.nextPrayerName == 'المغرب',
                      iconData: Icons.nights_stay_outlined,
                    ),
                    PrayerRowItem(
                      prayerName: AppStrings.isha,
                      prayerTime: prayerTimes.isha,
                      isNext: prayerTimes.nextPrayerName == 'العشاء',
                      iconData: Icons.bedtime,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Quick Access Features Grid
            const Text(
              'الخدمات والميزات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildQuickCard(
                  context,
                  title: 'أذكار الصباح',
                  subtitle: 'ابدأ يومك ببركة الذكر',
                  icon: Icons.wb_sunny,
                  gradient: AppColors.goldGradient,
                  isGold: true,
                  onTap: () {
                    context.read<AzkarBloc>().add(const LoadAzkarByCategoryEvent('أذكار الصباح'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ZikrReadingPage(categoryName: 'أذكار الصباح'),
                      ),
                    );
                  },
                ),
                _buildQuickCard(
                  context,
                  title: 'أذكار المساء',
                  subtitle: 'حصّن نفسك وأهلك',
                  icon: Icons.nights_stay,
                  gradient: AppColors.primaryGradient,
                  onTap: () {
                    context.read<AzkarBloc>().add(const LoadAzkarByCategoryEvent('أذكار المساء'));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ZikrReadingPage(categoryName: 'أذكار المساء'),
                      ),
                    );
                  },
                ),
                _buildQuickCard(
                  context,
                  title: 'التقويم الهجري',
                  subtitle: 'المناسبات والأيام المباركة',
                  icon: Icons.calendar_month,
                  gradient: AppColors.primaryGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarPage()),
                    );
                  },
                ),
                _buildQuickCard(
                  context,
                  title: 'أسماء الله الحسنى',
                  subtitle: '٩٩ اسماً ومعانيها',
                  icon: Icons.stars,
                  gradient: AppColors.goldGradient,
                  isGold: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AsmaaAllahPage()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Daily Ayah Inspiration Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.format_quote, color: AppColors.gold, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'آية وتدبر',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'سورة الرعد: الآية ٢٨',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool isGold = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isGold ? AppColors.goldDark : AppColors.primaryDark).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isGold ? Colors.black87 : AppColors.goldLight, size: 26),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isGold ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isGold ? Colors.black87 : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
