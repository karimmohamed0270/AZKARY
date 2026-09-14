import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/update_dialog.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/preference_service.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../prayer_times/bloc/prayer_times_bloc.dart';
import '../../../prayer_times/bloc/prayer_times_event.dart';
import '../../../prayer_times/bloc/prayer_times_state.dart';
import '../../../prayer_times/presentation/pages/city_picker_sheet.dart';

class SettingsPage extends StatefulWidget {
  final Function(String) onThemeChanged;

  const SettingsPage({super.key, required this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late PreferenceService _prefService;
  String _currentTheme = 'system';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _prefService = RepositoryProvider.of<PreferenceService>(context);
    _currentTheme = _prefService.getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      builder: (context, state) {
        final currentMethod = state.selectedMethod;
        final currentMadhab = state.selectedMadhab;
        final currentCity = state.prayerTimes?.cityName ?? 'القاهرة';

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.settings),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section 1: Prayer Calculation
              _buildSectionHeader('مواقيت الصلاة والموقع'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppColors.primary),
                      title: const Text('المدينة الحالية'),
                      subtitle: Text(currentCity),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => const CityPickerSheet(),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calculate, color: AppColors.primary),
                      title: const Text(AppStrings.calculationMethod),
                      subtitle: Text(_getMethodDisplayName(currentMethod)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showCalculationMethodDialog(context, currentMethod),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.school, color: AppColors.primary),
                      title: const Text(AppStrings.madhab),
                      subtitle: Text(currentMadhab == 'hanafi' ? 'المذهب الحنفي' : 'الجمهور (شافعي، مالكي، حنبلي)'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showMadhabDialog(context, currentMadhab),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                      title: const Text('تعديل المواقيت بالدقائق'),
                      subtitle: Text(_getAdjustmentsSummary(state)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showPrayerAdjustmentsSheet(context, state),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Appearance & Theme
              _buildSectionHeader('المظهر والثيم'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette, color: AppColors.primary),
                      title: const Text(AppStrings.themeMode),
                      subtitle: Text(_getThemeDisplayName(_currentTheme)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showThemeDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 4: About App & Updates
              _buildSectionHeader('معلومات وتحديث التطبيق'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: AppColors.primary),
                      title: const Text(AppStrings.aboutApp),
                      subtitle: const Text('تطبيق أذكاري - الإصدار 1.0.6 (Offline-First)'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showAboutAppDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.system_update_rounded, color: AppColors.primary),
                      title: const Text('التحقق من وجود تحديثات'),
                      subtitle: const Text('فحص وتثبيت الإصدارات الجديدة عبر GitHub'),
                      trailing: _isCheckingUpdate
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: _isCheckingUpdate ? null : _checkForUpdates,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _getMethodDisplayName(String method) {
    switch (method.toLowerCase()) {
      case 'makkah':
      case 'umm_al_qura':
        return 'جامعة أم القرى (مكة المكرمة)';
      case 'muslim_world_league':
      case 'mwl':
        return 'رابطة العالم الإسلامي';
      case 'karachi':
        return 'جامعة العلوم الإسلامية بكراتشي';
      case 'kuwait':
        return 'دولة الكويت';
      case 'qatar':
        return 'دولة قطر';
      case 'dubai':
        return 'دولة الإمارات (دبي)';
      case 'north_america':
      case 'isna':
        return 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';
      case 'turkey':
        return 'رئاسة الشؤون الدينية بتركيا';
      case 'egyptian':
      default:
        return 'الهيئة المصرية العامة للمساحة';
    }
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'dark':
        return AppStrings.darkMode;
      case 'light':
        return AppStrings.lightMode;
      default:
        return AppStrings.systemTheme;
    }
  }

  void _showCalculationMethodDialog(BuildContext context, String current) {
    final methods = [
      {'id': 'egyptian', 'name': 'الهيئة المصرية العامة للمساحة (مصر والدول المجاورة)'},
      {'id': 'makkah', 'name': 'جامعة أم القرى (المملكة العربية السعودية والخليج)'},
      {'id': 'muslim_world_league', 'name': 'رابطة العالم الإسلامي (أوروبا وأفريقيا)'},
      {'id': 'karachi', 'name': 'جامعة العلوم الإسلامية بكراتشي (باكستان والهند)'},
      {'id': 'dubai', 'name': 'دولة الإمارات العربية المتحدة'},
      {'id': 'kuwait', 'name': 'دولة الكويت'},
      {'id': 'qatar', 'name': 'دولة قطر'},
      {'id': 'north_america', 'name': 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.calculationMethod, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: methods.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = methods[index];
              final isSelected = m['id'] == current;

              return ListTile(
                title: Text(
                  m['name'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  context.read<PrayerTimesBloc>().add(UpdateCalculationMethodEvent(m['id'] as String));
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMadhabDialog(BuildContext context, String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.madhab, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('الجمهور (الشافعي، المالكي، الحنبلي)'),
              subtitle: const Text('وقت العصر إذا صار ظل الشيء مثله'),
              value: 'shafi',
              groupValue: current,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  context.read<PrayerTimesBloc>().add(UpdateMadhabEvent(val));
                  Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('المذهب الحنفي'),
              subtitle: const Text('وقت العصر إذا صار ظل الشيء مثليه'),
              value: 'hanafi',
              groupValue: current,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  context.read<PrayerTimesBloc>().add(UpdateMadhabEvent(val));
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.themeMode, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text(AppStrings.systemTheme),
              value: 'system',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _currentTheme = val);
                  await _prefService.setThemeMode(val);
                  widget.onThemeChanged(val);
                  if (mounted) Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text(AppStrings.lightMode),
              value: 'light',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _currentTheme = val);
                  await _prefService.setThemeMode(val);
                  widget.onThemeChanged(val);
                  if (mounted) Navigator.pop(ctx);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text(AppStrings.darkMode),
              value: 'dark',
              groupValue: _currentTheme,
              activeColor: AppColors.primary,
              onChanged: (val) async {
                if (val != null) {
                  setState(() => _currentTheme = val);
                  await _prefService.setThemeMode(val);
                  widget.onThemeChanged(val);
                  if (mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(AppStrings.appName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 2),
                Text('الإصدار 1.0.6', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'تطبيق إسلامي متكامل يعمل بالكامل دون الحاجة للاتصال بالإنترنت (Offline-First).',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 12),
              Text('مزايا التطبيق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text('• ضبط منبه الهاتف الرسمي لكل صلاة والتنبيه قبل الأذان'),
              Text('• حساب دقيق لمواقيت الصلاة محلياً وتعديل الدقائق وجدول الشهر'),
              Text('• القرآن الكريم كاملاً بـ ١١٤ سورة والبحث الفوري وتتبع الختمات'),
              Text('• حصن المسلم، أذكار الصباح والمساء، وأسماء الله الحسنى'),
              Text('• المسبحة الإلكترونية الذكية مع عداد يومي وإحصائيات'),
              Text('• التقويم الهجري والمناسبات الإسلامية وأيام الصيام المباركة'),
              Text('• يعمل بالكامل دون اتصال بالإنترنت وبدون أي إعلانات'),
              SizedBox(height: 16),
              Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.code, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'طُوِّر بواسطة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'كريم محمد حسن',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final updateService = getIt<AppUpdateService>();
      final result = await updateService.checkForUpdates(manualCheck: true);

      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);

      if (result.hasUpdate && result.latestRelease != null) {
        UpdateDialog.show(
          context: context,
          releaseInfo: result.latestRelease!,
          currentVersion: result.currentVersion,
          updateService: updateService,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  'أنت تستخدم أحدث إصدار من التطبيق (v${result.currentVersion})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: result.errorMessage != null
                ? (result.errorMessage!.contains('أحدث إصدار')
                    ? AppColors.primary
                    : AppColors.accentRed)
                : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingUpdate = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فحص التحديثات: $e'),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _getAdjustmentsSummary(PrayerTimesState state) {
    final list = <String>[];
    if (state.fajrAdjustment != 0) {
      list.add('الفجر (${state.fajrAdjustment > 0 ? '+' : ''}${ArabicNumbers.convert(state.fajrAdjustment)})');
    }
    if (state.dhuhrAdjustment != 0) {
      list.add('الظهر (${state.dhuhrAdjustment > 0 ? '+' : ''}${ArabicNumbers.convert(state.dhuhrAdjustment)})');
    }
    if (state.asrAdjustment != 0) {
      list.add('العصر (${state.asrAdjustment > 0 ? '+' : ''}${ArabicNumbers.convert(state.asrAdjustment)})');
    }
    if (state.maghribAdjustment != 0) {
      list.add('المغرب (${state.maghribAdjustment > 0 ? '+' : ''}${ArabicNumbers.convert(state.maghribAdjustment)})');
    }
    if (state.ishaAdjustment != 0) {
      list.add('العشاء (${state.ishaAdjustment > 0 ? '+' : ''}${ArabicNumbers.convert(state.ishaAdjustment)})');
    }

    if (list.isEmpty) {
      return 'تعديل يدوي لمطابقة أذان المسجد (+/- دقائق)';
    }
    return list.join('، ');
  }

  void _showPrayerAdjustmentsSheet(BuildContext context, PrayerTimesState state) {
    int fajr = state.fajrAdjustment;
    int sunrise = state.sunriseAdjustment;
    int dhuhr = state.dhuhrAdjustment;
    int asr = state.asrAdjustment;
    int maghrib = state.maghribAdjustment;
    int isha = state.ishaAdjustment;

    final baseFajr = state.prayerTimes != null
        ? state.prayerTimes!.fajr.subtract(Duration(minutes: state.fajrAdjustment))
        : null;
    final baseSunrise = state.prayerTimes != null
        ? state.prayerTimes!.sunrise.subtract(Duration(minutes: state.sunriseAdjustment))
        : null;
    final baseDhuhr = state.prayerTimes != null
        ? state.prayerTimes!.dhuhr.subtract(Duration(minutes: state.dhuhrAdjustment))
        : null;
    final baseAsr = state.prayerTimes != null
        ? state.prayerTimes!.asr.subtract(Duration(minutes: state.asrAdjustment))
        : null;
    final baseMaghrib = state.prayerTimes != null
        ? state.prayerTimes!.maghrib.subtract(Duration(minutes: state.maghribAdjustment))
        : null;
    final baseIsha = state.prayerTimes != null
        ? state.prayerTimes!.isha.subtract(Duration(minutes: state.ishaAdjustment))
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildAdjustItem({
              required String title,
              required IconData icon,
              required int value,
              required DateTime? baseTime,
              required ValueChanged<int> onChanged,
            }) {
              final adjustedTime = baseTime?.add(Duration(minutes: value));
              final formattedTime = adjustedTime != null
                  ? ArabicNumbers.formatTime12h(adjustedTime)
                  : '--:--';
              final isModified = value != 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isModified
                        ? AppColors.primary.withOpacity(0.08)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isModified
                          ? AppColors.primary.withOpacity(0.4)
                          : Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 13,
                                color: isModified ? AppColors.primary : Colors.grey.shade600,
                                fontWeight: isModified ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decrement button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline, size: 24),
                        color: value > -30 ? Colors.red.shade700 : Colors.grey.shade400,
                        onPressed: value > -30
                            ? () => setSheetState(() => onChanged(value - 1))
                            : null,
                      ),
                      // Value badge
                      Container(
                        constraints: const BoxConstraints(minWidth: 54),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isModified
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          value == 0
                              ? '٠ د'
                              : '${value > 0 ? '+' : ''}${ArabicNumbers.convert(value)} د',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isModified ? Colors.white : null,
                          ),
                        ),
                      ),
                      // Increment button
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        color: value < 30 ? AppColors.primary : Colors.grey.shade400,
                        onPressed: value < 30
                            ? () => setSheetState(() => onChanged(value + 1))
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعديل المواقيت بالدقائق',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'قم بزيادة أو إنقاص الدقائق لتتطابق تماماً مع مسجدك',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildAdjustItem(
                      title: 'صلاة الفجر',
                      icon: Icons.wb_twilight,
                      value: fajr,
                      baseTime: baseFajr,
                      onChanged: (v) => fajr = v,
                    ),
                    buildAdjustItem(
                      title: 'الشروق',
                      icon: Icons.wb_sunny_outlined,
                      value: sunrise,
                      baseTime: baseSunrise,
                      onChanged: (v) => sunrise = v,
                    ),
                    buildAdjustItem(
                      title: 'صلاة الظهر',
                      icon: Icons.wb_sunny,
                      value: dhuhr,
                      baseTime: baseDhuhr,
                      onChanged: (v) => dhuhr = v,
                    ),
                    buildAdjustItem(
                      title: 'صلاة العصر',
                      icon: Icons.filter_drama,
                      value: asr,
                      baseTime: baseAsr,
                      onChanged: (v) => asr = v,
                    ),
                    buildAdjustItem(
                      title: 'صلاة المغرب',
                      icon: Icons.nights_stay_outlined,
                      value: maghrib,
                      baseTime: baseMaghrib,
                      onChanged: (v) => maghrib = v,
                    ),
                    buildAdjustItem(
                      title: 'صلاة العشاء',
                      icon: Icons.bedtime,
                      value: isha,
                      baseTime: baseIsha,
                      onChanged: (v) => isha = v,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('إعادة ضبط'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              context.read<PrayerTimesBloc>().add(ResetPrayerAdjustmentsEvent());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('تمت استعادة المواقيت الافتراضية بنجاح.'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('حفظ وتطبيق'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              context.read<PrayerTimesBloc>().add(
                                UpdatePrayerAdjustmentsEvent(
                                  fajr: fajr,
                                  sunrise: sunrise,
                                  dhuhr: dhuhr,
                                  asr: asr,
                                  maghrib: maghrib,
                                  isha: isha,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('تم حفظ وتطبيق تعديل المواقيت بنجاح! 🕌'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
