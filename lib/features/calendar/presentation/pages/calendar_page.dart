import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/hijri_helper.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final events = HijriHelper.getIslamicEvents();
    final todayHijri = HijriHelper.getHijriCalendar();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hijriCalendar),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hijri Date Main Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.nightlight_round, color: AppColors.goldLight, size: 40),
                const SizedBox(height: 12),
                Text(
                  '${ArabicNumbers.convert(todayHijri.hDay)} ${HijriHelper.arabicMonths[todayHijri.hMonth - 1]} ${ArabicNumbers.convert(todayHijri.hYear)} هـ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'الموافق: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} م',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sunnah Fasting Days Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'أيام الصيام المستحبة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBulletItem('صيام الإثنين والخميس من كل أسبوع.'),
                _buildBulletItem('صيام الأيام البيض (١٣، ١٤، ١٥ من كل شهر هجري).'),
                _buildBulletItem('صيام يوم عرفة لغير الحاج (٩ ذو الحجة).'),
                _buildBulletItem('صيام يوم عاشوراء وتاسوعاء (٩ و ١٠ محرم).'),
                _buildBulletItem('صيام ستة أيام من شوال بعد عيد الفطر.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Islamic Annual Events List
          const Text(
            AppStrings.islamicEvents,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...events.map((e) {
            final isPassed = (todayHijri.hMonth > (e['month'] as int)) ||
                (todayHijri.hMonth == (e['month'] as int) && todayHijri.hDay > (e['day'] as int));

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? Colors.grey.withOpacity(0.15)
                        : AppColors.primaryContainer.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ArabicNumbers.convert(e['day']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.grey : AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  e['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPassed ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  '${ArabicNumbers.convert(e['day'])} ${e['month_name']}',
                  style: TextStyle(
                    color: isPassed ? Colors.grey : null,
                    fontSize: 12,
                  ),
                ),
                trailing: isPassed
                    ? const Text('مضى', style: TextStyle(color: Colors.grey, fontSize: 11))
                    : const Icon(Icons.stars, color: AppColors.gold, size: 20),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
