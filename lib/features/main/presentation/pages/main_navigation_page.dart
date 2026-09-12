import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/update_dialog.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../azkar/presentation/pages/azkar_home_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../quran/presentation/pages/quran_home_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../tasbeeh/presentation/pages/tasbeeh_page.dart';

class MainNavigationPage extends StatefulWidget {
  final Function(String) onThemeChanged;

  const MainNavigationPage({super.key, required this.onThemeChanged});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndChecks();
    });
  }

  Future<void> _initPermissionsAndChecks() async {
    // 1. Prompt for notifications permission on Android 13+ / iOS
    try {
      await getIt<NotificationService>().requestPermissions();
    } catch (_) {}

    // 2. Check for updates in background after delay
    await _checkUpdateSilently();
  }

  Future<void> _checkUpdateSilently() async {
    // Check in background after 4 seconds to avoid slowing down startup
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    try {
      final updateService = getIt<AppUpdateService>();
      final result = await updateService.checkForUpdates(manualCheck: false);

      if (result.hasUpdate && result.latestRelease != null && mounted) {
        UpdateDialog.show(
          context: context,
          releaseInfo: result.latestRelease!,
          currentVersion: result.currentVersion,
          updateService: updateService,
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      HomePage(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const QuranHomePage(),
      const AzkarHomePage(),
      const TasbeehPage(),
      SettingsPage(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: isDark ? AppColors.gold : AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: AppStrings.navQuran,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories),
              label: AppStrings.navAzkar,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radio_button_checked_outlined),
              activeIcon: Icon(Icons.radio_button_checked),
              label: AppStrings.navTasbeeh,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: AppStrings.settings,
            ),
          ],
        ),
      ),
    );
  }
}
