import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/tasbeeh_bloc.dart';
import '../../bloc/tasbeeh_event.dart';
import '../../bloc/tasbeeh_state.dart';
import '../widgets/tasbeeh_stats_sheet.dart';

class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;

    _scaleAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapCounter() {
    _pulseController.reverse().then((_) => _pulseController.forward());
    context.read<TasbeehBloc>().add(IncrementTasbeehEvent());
  }

  void _openStatsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TasbeehStatsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final target = state.targetCount;
        final progress = target > 0 ? (state.currentCount / target).clamp(0.0, 1.0) : 1.0;
        final isGoalMet = state.todayCount >= state.dailyGoal;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.electronicTasbeeh),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'إحصائيات الورد الشهري',
                onPressed: () => _openStatsSheet(context),
              ),
              IconButton(
                icon: Icon(
                  state.isHapticEnabled ? Icons.vibration : Icons.mobile_off,
                  color: state.isHapticEnabled ? AppColors.gold : Colors.grey,
                ),
                tooltip: 'الاهتزاز',
                onPressed: () => context.read<TasbeehBloc>().add(ToggleHapticEvent()),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'إعادة تصفير العداد',
                onPressed: () => _confirmResetDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Dhikr Selector Bar
                  _buildDhikrSelector(context, state, isDark),
                  const SizedBox(height: 14),

                  // 2. Daily Wird Quick Progress Card (تحفيز الورد اليومي)
                  _buildDailyWirdBanner(context, state, isDark, isGoalMet),
                  const SizedBox(height: 16),

                  // 3. Target Selector Pills (33, 99, 100, مفتوح) - هندسة متناسقة وبدون علامات مشوهة
                  _buildTargetSelector(context, state, isDark),
                  const SizedBox(height: 28),

                  // 4. Main Circular Tap Counter Area with Smooth Scale Feedback
                  Center(
                    child: GestureDetector(
                      onTapDown: (_) => _pulseController.reverse(),
                      onTapUp: (_) => _pulseController.forward(),
                      onTapCancel: () => _pulseController.forward(),
                      onTap: _onTapCounter,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SizedBox(
                          width: 250,
                          height: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer decorative glowing ring
                              Container(
                                width: 246,
                                height: 246,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),

                              // Inner Gradient Circle with Ambient Shadow
                              Container(
                                width: 232,
                                height: 232,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isGoalMet
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF0F5A47), Color(0xFF072920)],
                                        )
                                      : AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryDark.withValues(alpha: 0.45),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),

                              // Progress Arc
                              SizedBox(
                                width: 232,
                                height: 232,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 9,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                                ),
                              ),

                              // Center Counter Display with Crystal Clear Numbers
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Counter Number: Clean, Bold, and never distorted
                                  Text(
                                    ArabicNumbers.convert(state.currentCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 60,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Target Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      target > 0
                                          ? 'الهدف: ${ArabicNumbers.convert(target)}'
                                          : AppStrings.freeCount,
                                      style: const TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Tap Hint
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        size: 14,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'اضغط للتسبيح',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Bottom Stats Summary Cards (الدورة الحالية & إجمالي التسبيح)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.loop_rounded,
                          title: AppStrings.currentCycle,
                          value: '${ArabicNumbers.convert(state.currentCycle)} دورة',
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.all_inclusive_rounded,
                          title: AppStrings.totalDhikr,
                          value: '${ArabicNumbers.convert(state.totalLifetimeCount)} تسبيحة',
                          color: AppColors.gold,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Large Monthly Chart & Streak Action Button
                  InkWell(
                    onTap: () => _openStatsSheet(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF133E33), Color(0xFF0D2821)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 1.2),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: AppColors.goldLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سجل الورد والرسم البياني الشهري',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'تابع إنجازك اليومي والشهري وتفاصيل الالتزام',
                                  style: TextStyle(
                                    color: AppColors.goldLight,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.goldLight,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDhikrSelector(BuildContext context, TasbeehState state, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDhikrPicker(context, state),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.selectDhikr,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.selectedDhikr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyWirdBanner(
    BuildContext context,
    TasbeehState state,
    bool isDark,
    bool isGoalMet,
  ) {
    final wirdProgress =
        state.dailyGoal > 0 ? (state.todayCount / state.dailyGoal).clamp(0.0, 1.0) : 1.0;

    return InkWell(
      onTap: () => _openStatsSheet(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isGoalMet
                ? AppColors.gold.withValues(alpha: 0.6)
                : (isDark ? Colors.white12 : Colors.black12),
            width: isGoalMet ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    Icon(
                      isGoalMet ? Icons.check_circle_rounded : Icons.track_changes_rounded,
                      color: isGoalMet ? AppColors.gold : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الورد اليومي',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${ArabicNumbers.convert(state.todayCount)} / ${ArabicNumbers.convert(state.dailyGoal)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isGoalMet ? AppColors.goldDark : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${ArabicNumbers.convert(state.streakDays)} يوم',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: wirdProgress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalMet ? AppColors.gold : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSelector(BuildContext context, TasbeehState state, bool isDark) {
    final targets = [
      {'target': 33, 'label': '٣٣'},
      {'target': 99, 'label': '٩٩'},
      {'target': 100, 'label': '١٠٠'},
      {'target': 0, 'label': 'مفتوح'},
    ];

    return Row(
      children: targets.map((item) {
        final targetVal = item['target'] as int;
        final label = item['label'] as String;
        final isSelected = state.targetCount == targetVal;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => context.read<TasbeehBloc>().add(SetTargetCountEvent(targetVal)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected
                      ? null
                      : (isDark ? AppColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.goldLight
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDhikrPicker(BuildContext context, TasbeehState state) {
    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.selectDhikr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Dhikr List
              ...state.availableDhikrs.map((d) {
                final isSelected = state.selectedDhikr == d;
                return ListTile(
                  title: Text(
                    d,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  trailing:
                      isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    context.read<TasbeehBloc>().add(SelectDhikrEvent(d));
                    Navigator.pop(ctx);
                  },
                );
              }),

              const Divider(height: 20),

              // Custom Dhikr input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customController,
                      decoration: const InputDecoration(
                        hintText: 'أدخل ذكراً مخصصاً...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (customController.text.trim().isNotEmpty) {
                        context
                            .read<TasbeehBloc>()
                            .add(SelectDhikrEvent(customController.text.trim()));
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير العداد', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل ترغب في تصفير العداد الحالي فقط أم تصفير الإجمالي بالكامل؟'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<TasbeehBloc>().add(ResetCurrentCounterEvent());
              Navigator.pop(ctx);
            },
            child: const Text('العداد الحالي فقط'),
          ),
          TextButton(
            onPressed: () {
              context.read<TasbeehBloc>().add(ResetTotalCounterEvent());
              Navigator.pop(ctx);
            },
            child: const Text('تصفير الكل', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }
}
