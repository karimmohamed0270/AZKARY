import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../prayer_times/bloc/prayer_times_bloc.dart';
import '../../../prayer_times/bloc/prayer_times_state.dart';
import '../../../prayer_times/presentation/pages/city_picker_sheet.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double _smoothHeading = 0.0;
  bool _hasSensor = true;
  bool _lastAligned = false;
  StreamSubscription<CompassEvent>? _compassSub;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen(
      (CompassEvent event) {
        if (!mounted || event.heading == null) return;

        final double raw = (event.heading! + 360) % 360;

        // Smooth angular filtering to remove sensor jitter
        double diff = raw - _smoothHeading;
        while (diff < -180) {
          diff += 360;
        }
        while (diff > 180) {
          diff -= 360;
        }

        setState(() {
          _smoothHeading = (_smoothHeading + diff * 0.25 + 360) % 360;
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _hasSensor = false;
          });
        }
      },
    );
  }

  void _triggerHapticIfNewlyAligned(bool isAligned) {
    if (isAligned && !_lastAligned) {
      HapticFeedback.mediumImpact();
      _lastAligned = true;
    } else if (!isAligned) {
      _lastAligned = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      builder: (context, state) {
        final qiblaAngle = state.qiblaAngleDegrees;
        final distanceKm = state.distanceToKaabaKm;
        final cityName = state.prayerTimes?.cityName ?? 'القاهرة';

        // Delta between current phone heading and Qibla target (-180 to +180)
        final double delta = ((qiblaAngle - _smoothHeading) + 540) % 360 - 180;
        final bool isAligned = delta.abs() < 4.0;

        _triggerHapticIfNewlyAligned(isAligned);

        String directionGuidance;
        if (isAligned) {
          directionGuidance = 'أنت متجه نحو القبلة تماماً 🕋';
        } else if (delta > 0) {
          directionGuidance = 'در بمقدار ${ArabicNumbers.convert(delta.abs().round())}° لليمين ↻';
        } else {
          directionGuidance = 'در بمقدار ${ArabicNumbers.convert(delta.abs().round())}° لليسار ↺';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.qiblaCompass),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_location_alt_outlined),
                tooltip: 'تغيير الموقع',
                onPressed: () => _openCityPicker(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Info Card: Location, Qibla Angle, Distance
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.goldLight, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                cityName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.goldLight,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('تغيير / GPS', style: TextStyle(fontSize: 12)),
                            onPressed: () => _openCityPicker(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('زاوية القبلة', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '${ArabicNumbers.convert(qiblaAngle.toStringAsFixed(1))}°',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(height: 26, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('اتجاه هاتفك', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '${ArabicNumbers.convert(_smoothHeading.round())}°',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(height: 26, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('المسافة لمكة', style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '${ArabicNumbers.convert(distanceKm.toInt())} كم',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Direction Guidance Status Banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isAligned
                        ? AppColors.primary
                        : (isDark ? AppColors.cardDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAligned ? AppColors.gold : Colors.grey.withOpacity(0.3),
                      width: isAligned ? 2.5 : 1,
                    ),
                    boxShadow: isAligned
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle : Icons.explore,
                        color: isAligned ? AppColors.goldLight : AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        directionGuidance,
                        style: TextStyle(
                          color: isAligned
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Compass Dial & Needle
                if (!_hasSensor)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentRed.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.sensors_off_rounded, color: AppColors.accentRed, size: 40),
                        SizedBox(height: 12),
                        Text(
                          AppStrings.sensorNotAvailable,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.accentRed, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'هاتفك لا يحتوي على حساس البوصلة المغناطيسية. يمكنك الاعتماد على زاوية القبلة بالأعلى مع الشمس أو الخريطة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: 290,
                    height: 290,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Compass Dial Ring (Rotates with -heading so N points North)
                        Transform.rotate(
                          angle: -(_smoothHeading * (math.pi / 180)),
                          child: Container(
                            width: 290,
                            height: 290,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppColors.cardDark : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: isAligned
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                color: isAligned
                                    ? AppColors.gold
                                    : AppColors.primary.withOpacity(0.35),
                                width: isAligned ? 3 : 2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Cardinal Direction Letters
                                const Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'شمال (N)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accentRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'جنوب (S)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'شرق (E)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'غرب (W)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                                // Kaaba Icon located on the Dial Ring at qiblaAngle
                                Transform.rotate(
                                  angle: qiblaAngle * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 32),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.goldDark.withOpacity(0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.mosque,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Kaaba Pointer Needle (Points towards Kaaba relative to phone)
                        // Angle is (qiblaAngle - _smoothHeading)
                        Transform.rotate(
                          angle: (qiblaAngle - _smoothHeading) * (math.pi / 180),
                          child: SizedBox(
                            width: 50,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Top half: Kaaba pointer needle (pointing up)
                                Positioned(
                                  top: 15,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.navigation,
                                        size: 44,
                                        color: isAligned ? AppColors.gold : AppColors.primary,
                                      ),
                                      Container(
                                        width: 4,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isAligned ? AppColors.gold : AppColors.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Bottom half: Counterweight needle tail
                                Positioned(
                                  bottom: 25,
                                  child: Container(
                                    width: 4,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                // Center Pivot Circle
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAligned ? AppColors.gold : AppColors.primary,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 28),

                // Compass Calibration Advice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.35)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.screen_rotation, color: Colors.amber, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'للحصول على أعلى دقة، حرّك الهاتف في الهواء على شكل رقم (8) لمعايرة البوصلة المغناطيسية، وتأكد من الابتعاد عن الأجهزة الإلكترونية أو القطع المعدنية.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CityPickerSheet(),
    );
  }
}
