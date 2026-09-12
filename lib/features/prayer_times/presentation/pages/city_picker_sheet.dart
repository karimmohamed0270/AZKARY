import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/preference_service.dart';
import '../../bloc/prayer_times_bloc.dart';
import '../../bloc/prayer_times_event.dart';
import '../../bloc/prayer_times_state.dart';

class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({super.key});

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLocating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleGpsLocation() async {
    setState(() => _isLocating = true);

    final locationService = getIt<LocationService>();
    final result = await locationService.getCurrentLocationDetailed();

    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.isSuccess && result.position != null) {
      final pos = result.position!;
      final nearestName = result.nearestCity != null
          ? 'موقعي الحالي (${result.nearestCity!.nameAr})'
          : 'موقعي الحالي (GPS)';

      await getIt<PreferenceService>().setLocation(
        cityNameAr: nearestName,
        cityNameEn: result.nearestCity?.nameEn ?? 'Current Location',
        latitude: pos.latitude,
        longitude: pos.longitude,
        isGps: true,
      );

      if (mounted) {
        context.read<PrayerTimesBloc>().add(LoadPrayerTimesEvent());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('تم تحديد موقعك بنجاح: $nearestName')),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else {
      if (result.status == LocationResultStatus.serviceDisabled) {
        _showEnableGpsDialog(context, locationService);
      } else if (result.status == LocationResultStatus.permissionDeniedForever) {
        _showOpenSettingsDialog(context, locationService);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'تعذر تحديد الموقع.'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showEnableGpsDialog(BuildContext context, LocationService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppColors.accentAmber),
            SizedBox(width: 8),
            Text('تفعيل خدمة الموقع (GPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'خدمة الموقع (GPS) غير مفعلة على هاتفك. يرجى تشغيلها لتحديد مواقيت الصلاة واتجاه القبلة بدقة.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              service.openLocationSettings();
            },
            child: const Text('فتح إعدادات الموقع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog(BuildContext context, LocationService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text('إذن الموقع مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'تم رفض إذن الوصول للموقع بشكل دائم. يرجى السماح للتطبيق بإذن الموقع من إعدادات الهاتف.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              service.openAppSettings();
            },
            child: const Text('إعدادات التطبيق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      builder: (context, state) {
        final cities = state.availableCities.where((c) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;
          return c.nameAr.toLowerCase().contains(query) ||
              c.nameEn.toLowerCase().contains(query) ||
              c.countryAr.toLowerCase().contains(query) ||
              c.countryEn.toLowerCase().contains(query);
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                AppStrings.changeLocation,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // GPS Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _isLocating ? 'جاري التقاط إشارة GPS...' : AppStrings.useGps,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _isLocating ? null : _handleGpsLocation,
              ),
              const SizedBox(height: 12),

              // Search field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم المدينة أو المحافظة...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Cities List
              Expanded(
                child: ListView.separated(
                  itemCount: cities.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = state.prayerTimes?.cityName == city.nameAr;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        city.nameAr,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      subtitle: Text('${city.countryAr} (${city.nameEn})'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        context.read<PrayerTimesBloc>().add(ChangeCityEvent(city));
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
