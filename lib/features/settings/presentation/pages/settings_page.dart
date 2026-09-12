import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/update_dialog.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/preference_service.dart';
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
  bool _adhanNotif = true;
  bool _azkarNotif = true;
  String _currentTheme = 'system';
  bool _isCheckingUpdate = false;
  bool _isPlayingAdhan = false;
  StreamSubscription<PlayerState>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    _prefService = RepositoryProvider.of<PreferenceService>(context);
    _adhanNotif = _prefService.isAdhanNotificationEnabled();
    _azkarNotif = _prefService.isAzkarNotificationEnabled();
    _currentTheme = _prefService.getThemeMode();

    _audioSubscription =
        getIt<AudioService>().onPlayerStateChanged.listen((pState) {
      if (mounted) {
        setState(() {
          _isPlayingAdhan = pState == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    getIt<AudioService>().stopAudio();
    super.dispose();
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Notifications
              _buildSectionHeader(AppStrings.notifications),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active, color: AppColors.primary),
                      title: const Text(AppStrings.adhanNotification),
                      subtitle: const Text('تنبيه الأذان بصوت الأذان والتكبيرات عند كل صلاة'),
                      value: _adhanNotif,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) async {
                        setState(() => _adhanNotif = val);
                        if (val) {
                          await getIt<NotificationService>().requestPermissions();
                        }
                        await _prefService.setAdhanNotification(val);
                        if (mounted) {
                          context.read<PrayerTimesBloc>().add(LoadPrayerTimesEvent());
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.alarm, color: AppColors.primary),
                      title: const Text('تنبيه الأذكار اليومية'),
                      subtitle: const Text('تذكير يومي بأذكار الصباح (6:30 ص) والمساء (5:00 م)'),
                      value: _azkarNotif,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) async {
                        setState(() => _azkarNotif = val);
                        if (val) {
                          await getIt<NotificationService>().requestPermissions();
                        }
                        await _prefService.setAzkarNotification(val);
                        if (mounted) {
                          context.read<PrayerTimesBloc>().add(LoadPrayerTimesEvent());
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        _isPlayingAdhan ? Icons.stop_circle : Icons.volume_up_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      title: Text(_isPlayingAdhan ? 'إيقاف صوت الأذان' : 'الاستماع لصوت الأذان (معاينة)'),
                      subtitle: const Text('تجربة صوت الأذان المعتمد لمواقيت الصلاة'),
                      trailing: Icon(
                        _isPlayingAdhan ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      onTap: () async {
                        final audioService = getIt<AudioService>();
                        if (_isPlayingAdhan) {
                          await audioService.stopAudio();
                        } else {
                          await audioService.playAdhan();
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      title: const Text('إرسال إشعار تجريبي بالصوت الآن'),
                      subtitle: const Text('اختبار ظهور إشعار الأذان وتشغيل الصوت على هاتفك فوراً'),
                      trailing: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                      onTap: () async {
                        try {
                          final notifService = getIt<NotificationService>();
                          
                          final hasPerm = await notifService.requestPermissions();
                          if (!hasPerm && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('يرجى التأكد من تفعيل إذن الإشعارات من إعدادات الهاتف')),
                                  ],
                                ),
                                backgroundColor: Colors.orange.shade800,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }

                          await notifService.showInstantNotification(
                            title: '🕌 حان الآن موعد الأذان (إشعار تجريبي)',
                            body: 'حي على الصلاة، حي على الفلاح.. تم اختبار الصوت والتنبيه بنجاح.',
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('تم إرسال إشعار تجريبي بصوت الأذان! تفقد شريط الإشعارات 🔔')),
                                  ],
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء الإشعار: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Appearance & Theme
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
                      subtitle: const Text('تطبيق أذكاري - الإصدار 1.0.0 (Offline-First)'),
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
            const Text(AppStrings.appName, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'تطبيق إسلامي متكامل يعمل بالكامل دون الحاجة للاتصال بالإنترنت (Offline-First).',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('الميزات الأساسية:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• القرآن الكريم كاملاً بـ ١١٤ سورة والبحث الفوري'),
            Text('• حساب دقيق لمواقيت الصلاة محلياً لجميع بلدان العالم'),
            Text('• بوصلة القبلة التفاعلية الفلكية'),
            Text('• حصن المسلم، الأذكار والمسبحة الإلكترونية الذكية'),
            Text('• التقويم الهجري والمناسبات الإسلامية وأيام الصيام'),
          ],
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
}
