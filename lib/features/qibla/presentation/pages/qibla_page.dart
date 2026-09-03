import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../prayer_times/bloc/prayer_times_bloc.dart';
import '../../../prayer_times/bloc/prayer_times_state.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _heading = 0.0;
  bool _hasSensor = true;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  void _initCompass() {
    FlutterCompass.events?.listen(
      (event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
      builder: (context, state) {
        final qiblaAngle = state.qiblaAngleDegrees;
        final distanceKm = state.distanceToKaabaKm;
        final cityName = state.prayerTimes?.cityName ?? 'القاهرة';

        // Calculate needle rotation: (heading - qiblaAngle)
        final headingVal = _heading ?? 0.0;
        final difference = (headingVal - qiblaAngle);
        final isAligned = difference.abs() < 4.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.qiblaCompass),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Info Card: Location & Distance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'المدينة',
                            style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cityName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text(
                            'زاوية القبلة',
                            style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ArabicNumbers.convert(qiblaAngle.toStringAsFixed(1))}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text(
                            'المسافة لمكة',
                            style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ArabicNumbers.convert(distanceKm.toInt())} كم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Alignment Status Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAligned
                        ? AppColors.primary
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAligned ? AppColors.gold : Colors.grey.withOpacity(0.3),
                      width: isAligned ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle : Icons.explore,
                        color: isAligned ? AppColors.goldLight : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAligned ? 'أنت متجه نحو القبلة تماماً 🕋' : AppStrings.alignWithKaaba,
                        style: TextStyle(
                          color: isAligned ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Compass Dial
                if (!_hasSensor)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        AppStrings.sensorNotAvailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.accentRed, fontSize: 16),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Compass Dial background (rotates with heading)
                        Transform.rotate(
                          angle: -((_heading ?? 0) * (math.pi / 180)),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                color: isAligned ? AppColors.gold : AppColors.primary.withOpacity(0.4),
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Cardinal points: N, E, S, W
                                const Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('شمال (N)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentRed, fontSize: 11)),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('جنوب (S)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('شرق (E)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('غرب (W)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                                  ),
                                ),

                                // Kaaba Direction Icon on the dial ring
                                Transform.rotate(
                                  angle: qiblaAngle * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 26),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.goldDark.withOpacity(0.4),
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

                        // Center Needle / Kaaba Arrow
                        Transform.rotate(
                          angle: -(difference * (math.pi / 180)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.navigation,
                                size: 56,
                                color: isAligned ? AppColors.gold : AppColors.primary,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),

                        // Center Pivot Point
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isAligned ? AppColors.gold : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 36),

                // Calibration Tip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.compassCalibrate,
                          style: TextStyle(fontSize: 12),
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
}
