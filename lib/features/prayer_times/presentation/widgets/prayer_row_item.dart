import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import 'prayer_alarm_sheet.dart';

class PrayerRowItem extends StatelessWidget {
  final String prayerName;
  final DateTime prayerTime;
  final bool isNext;
  final IconData iconData;

  const PrayerRowItem({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    required this.isNext,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNext
            ? (isDark ? AppColors.cardDarkSecondary : AppColors.primaryContainer.withOpacity(0.6))
            : (isDark ? AppColors.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext
              ? AppColors.gold
              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.gold.withOpacity(0.2)
                  : (isDark ? AppColors.surfaceDark : AppColors.primary.withOpacity(0.08)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              size: 20,
              color: isNext ? AppColors.goldDark : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              prayerName,
              style: TextStyle(
                fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                fontSize: 15,
                color: isNext
                    ? (isDark ? AppColors.goldLight : AppColors.primary)
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ),
          Text(
            ArabicNumbers.formatTime12h(prayerTime),
            style: TextStyle(
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              color: isNext
                  ? (isDark ? AppColors.goldLight : AppColors.primary)
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'ضبط منبه الهاتف',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  PrayerAlarmSheet.show(
                    context,
                    prayerName: prayerName,
                    prayerTime: prayerTime,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.alarm_add_rounded,
                    size: 20,
                    color: isNext
                        ? (isDark ? AppColors.goldLight : AppColors.primary)
                        : (isDark ? Colors.white70 : Colors.black45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
