import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/tasbeeh_bloc.dart';
import '../../bloc/tasbeeh_event.dart';
import '../../bloc/tasbeeh_state.dart';

class TasbeehPage extends StatelessWidget {
  const TasbeehPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbeehBloc, TasbeehState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final target = state.targetCount;
        final progress = target > 0 ? (state.currentCount / target).clamp(0.0, 1.0) : 1.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.electronicTasbeeh),
            actions: [
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
          body: Column(
            children: [
              // Top Dhikr Selector Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),

              // Target Selector Chips (33, 99, 100, Free)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTargetChip(context, 33, '٣٣', state.targetCount == 33),
                    const SizedBox(width: 8),
                    _buildTargetChip(context, 99, '٩٩', state.targetCount == 99),
                    const SizedBox(width: 8),
                    _buildTargetChip(context, 100, '١٠٠', state.targetCount == 100),
                    const SizedBox(width: 8),
                    _buildTargetChip(context, 0, 'مفتوح', state.targetCount == 0),
                  ],
                ),
              ),

              const Spacer(),

              // Main Circular Tap Counter Area
              Center(
                child: GestureDetector(
                  onTap: () => context.read<TasbeehBloc>().add(IncrementTasbeehEvent()),
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle shadow
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),

                        // Progress Arc
                        SizedBox(
                          width: 230,
                          height: 230,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                          ),
                        ),

                        // Center Counter Display
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ArabicNumbers.convert(state.currentCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (target > 0)
                              Text(
                                'الهدف: ${ArabicNumbers.convert(target)}',
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              const Text(
                                AppStrings.freeCount,
                                style: TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'اضغط للتسبيح',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Bottom Stats Summary (Cycles, Total Count)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              AppStrings.currentCycle,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ArabicNumbers.convert(state.currentCycle),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              AppStrings.totalDhikr,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ArabicNumbers.convert(state.totalLifetimeCount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTargetChip(BuildContext context, int target, String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => context.read<TasbeehBloc>().add(SetTargetCountEvent(target)),
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
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
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
                        context.read<TasbeehBloc>().add(SelectDhikrEvent(customController.text.trim()));
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
