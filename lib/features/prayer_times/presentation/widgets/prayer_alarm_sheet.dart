import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/system_alarm_service.dart';
import '../../../../core/utils/arabic_numbers.dart';

class PrayerAlarmSheet extends StatelessWidget {
  final String prayerName;
  final DateTime prayerTime;

  const PrayerAlarmSheet({
    super.key,
    required this.prayerName,
    required this.prayerTime,
  });

  static Future<void> show(
    BuildContext context, {
    required String prayerName,
    required DateTime prayerTime,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrayerAlarmSheet(
        prayerName: prayerName,
        prayerTime: prayerTime,
      ),
    );
  }

  Future<void> _handleSetAlarm(BuildContext context, int offsetMinutes) async {
    final targetTime = prayerTime.add(Duration(minutes: offsetMinutes));

    final result = await SystemAlarmService.setPrayerAlarm(
      prayerName: prayerName,
      prayerTime: prayerTime,
      offsetMinutes: offsetMinutes,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: result.isSuccess ? AppColors.primary : Colors.orange.shade800,
        content: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.alarm_on_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.isSuccess
                    ? 'تم فتح تطبيق المنبه لضبط صلاة $prayerName (${ArabicNumbers.formatTime12h(targetTime)})'
                    : (result.errorMessage ?? 'تعذر فتح تطبيق المنبه'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedTime = ArabicNumbers.formatTime12h(prayerTime);
    final isSunrise = prayerName == 'الشروق';

    final timeMinus15 = prayerTime.subtract(const Duration(minutes: 15));
    final timeMinus30 = prayerTime.subtract(const Duration(minutes: 30));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.alarm_add_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSunrise
                            ? 'ضبط منبه هاتف لوقت الشروق'
                            : 'ضبط منبه هاتف لصلاة $prayerName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSunrise ? 'موعد الشروق: $formattedTime' : 'موعد الأذان: $formattedTime',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Option 1: Exact Time
            _buildAlarmOption(
              context: context,
              icon: Icons.notifications_active_rounded,
              title: isSunrise ? 'في موعد الشروق تماماً' : 'في موعد الأذان تماماً',
              subtitle: isSunrise
                  ? 'رنين المنبه مع وقت شروق الشمس'
                  : 'رنين المنبه عند رفع أذان $prayerName',
              timeBadge: formattedTime,
              isPrimary: true,
              onTap: () => _handleSetAlarm(context, 0),
            ),
            const SizedBox(height: 10),

            // Option 2: 15 minutes before
            _buildAlarmOption(
              context: context,
              icon: Icons.access_time_filled_rounded,
              title: isSunrise ? 'قبل الشروق بـ ١٥ دقيقة' : 'قبل الأذان بـ ١٥ دقيقة',
              subtitle: isSunrise
                  ? 'لإدراك صلاة الفجر قبل خروج وقتها'
                  : 'للاستيقاظ والوضوء والاستعداد للصلاة',
              timeBadge: ArabicNumbers.formatTime12h(timeMinus15),
              isPrimary: false,
              onTap: () => _handleSetAlarm(context, -15),
            ),
            const SizedBox(height: 10),

            // Option 3: 30 minutes before
            _buildAlarmOption(
              context: context,
              icon: Icons.nightlight_round,
              title: isSunrise ? 'قبل الشروق بـ ٣٠ دقيقة' : 'قبل الأذان بـ ٣٠ دقيقة',
              subtitle: isSunrise
                  ? 'للاستعداد وصلاة الفجر براحة'
                  : (prayerName == 'الفجر'
                      ? 'لقيام الليل والوتر أو السحور قبل الفجر'
                      : 'للاستعداد المبكر والذهاب للمسجد'),
              timeBadge: ArabicNumbers.formatTime12h(timeMinus30),
              isPrimary: false,
              onTap: () => _handleSetAlarm(context, -30),
            ),
            const SizedBox(height: 16),

            // Tip Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withOpacity(0.5)
                    : AppColors.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يتم ضبط المنبه في تطبيق منبه الهاتف الرسمي، مما يضمن رنينه في موعده بدقة دون تأثر بوضع توفير الطاقة.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String timeBadge,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? (isDark ? AppColors.cardDark : AppColors.primaryContainer.withOpacity(0.45))
                : (isDark ? AppColors.surfaceDark.withOpacity(0.6) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary
                  ? AppColors.primary.withOpacity(0.4)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isPrimary ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primary.withOpacity(0.15)
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? AppColors.primary : (isDark ? Colors.white70 : Colors.grey.shade700),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                        color: isPrimary ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primary
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  timeBadge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
