import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/tasbeeh_bloc.dart';
import '../../bloc/tasbeeh_event.dart';
import '../../bloc/tasbeeh_state.dart';

class TasbeehStatsSheet extends StatefulWidget {
  const TasbeehStatsSheet({super.key});

  @override
  State<TasbeehStatsSheet> createState() => _TasbeehStatsSheetState();
}

class _TasbeehStatsSheetState extends State<TasbeehStatsSheet> {
  late DateTime _selectedMonth;
  int? _tappedDay;

  final List<String> _arabicMonths = const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _tappedDay = now.day;
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _tappedDay = null;
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
        _tappedDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return BlocBuilder<TasbeehBloc, TasbeehState>(
      builder: (context, state) {
        final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
        final history = state.dailyHistory;

        // Calculate monthly metrics
        int totalMonthCount = 0;
        int maxDayCount = 0;
        int bestDay = 1;
        int daysGoalMet = 0;

        final Map<int, int> daysData = {};
        for (int day = 1; day <= daysInMonth; day++) {
          final key =
              '${_selectedMonth.year.toString().padLeft(4, '0')}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final count = history[key] ?? 0;
          daysData[day] = count;
          totalMonthCount += count;
          if (count > maxDayCount) {
            maxDayCount = count;
            bestDay = day;
          }
          if (count >= state.dailyGoal) {
            daysGoalMet++;
          }
        }

        final selectedDayCount = _tappedDay != null ? (daysData[_tappedDay!] ?? 0) : 0;
        final monthName = _arabicMonths[_selectedMonth.month - 1];

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title & Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'متابعة الورد والرسم البياني',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Streak & Today Wird Banner
                _buildTopProgressBanner(state, isDark),
                const SizedBox(height: 16),

                // Month Navigation Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 28),
                        tooltip: 'الشهر السابق',
                        onPressed: _prevMonth,
                      ),
                      Column(
                        children: [
                          Text(
                            '$monthName ${ArabicNumbers.convert(_selectedMonth.year)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'إجمالي الشهر: ${ArabicNumbers.convert(totalMonthCount)} تسبيحة',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.goldLight : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        tooltip: 'الشهر التالي',
                        onPressed: isCurrentMonth ? null : _nextMonth,
                        color: isCurrentMonth ? Colors.grey.withValues(alpha: 0.3) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4 Mini Stat Badges
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.calendar_today_rounded,
                        title: 'أيام الورد',
                        value: '${ArabicNumbers.convert(daysGoalMet)} يوم',
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.emoji_events_rounded,
                        title: 'أعلى يوم',
                        value: maxDayCount > 0
                            ? '${ArabicNumbers.convert(maxDayCount)} (يوم ${ArabicNumbers.convert(bestDay)})'
                            : '٠',
                        color: AppColors.gold,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStat(
                        icon: Icons.local_fire_department_rounded,
                        title: 'الالتزام',
                        value: '${ArabicNumbers.convert(state.streakDays)} يوم',
                        color: Colors.deepOrange,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Selected Day Info Card
                if (_tappedDay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: selectedDayCount >= state.dailyGoal
                          ? AppColors.gold.withValues(alpha: 0.14)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedDayCount >= state.dailyGoal
                            ? AppColors.gold
                            : AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selectedDayCount >= state.dailyGoal
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: selectedDayCount >= state.dailyGoal
                                  ? AppColors.gold
                                  : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'يوم ${ArabicNumbers.convert(_tappedDay)} $monthName:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${ArabicNumbers.convert(selectedDayCount)} تسبيحة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selectedDayCount >= state.dailyGoal
                                    ? AppColors.goldDark
                                    : AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (selectedDayCount >= state.dailyGoal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'الورد مكتمل ✓',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // THE MONTHLY BAR CHART
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'مخطط التسبيح اليومي',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'الهدف اليومي: ${ArabicNumbers.convert(state.dailyGoal)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Horizontal Scrollable Bar Chart
                      SizedBox(
                        height: 170,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final chartMax = (maxDayCount > state.dailyGoal
                                    ? maxDayCount
                                    : state.dailyGoal) *
                                1.15;

                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: daysInMonth,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final day = index + 1;
                                final count = daysData[day] ?? 0;
                                final isToday = isCurrentMonth && day == now.day;
                                final isSelected = day == _tappedDay;
                                final isGoalAchieved = count >= state.dailyGoal;
                                final barHeightFactor =
                                    chartMax > 0 ? (count / chartMax).clamp(0.05, 1.0) : 0.05;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _tappedDay = day;
                                    });
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Top indicator icon if goal achieved
                                      SizedBox(
                                        height: 16,
                                        child: isGoalAchieved
                                            ? const Icon(
                                                Icons.star_rounded,
                                                color: AppColors.gold,
                                                size: 14,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 2),

                                      // The Bar
                                      Container(
                                        width: 22,
                                        height: 100 * barHeightFactor,
                                        decoration: BoxDecoration(
                                          gradient: isGoalAchieved
                                              ? const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [AppColors.gold, Color(0xFFB8860B)],
                                                )
                                              : (count > 0
                                                  ? AppColors.primaryGradient
                                                  : null),
                                          color: count == 0
                                              ? (isDark
                                                  ? Colors.white.withValues(alpha: 0.06)
                                                  : Colors.black.withValues(alpha: 0.05))
                                              : null,
                                          borderRadius: BorderRadius.circular(6),
                                          border: isSelected
                                              ? Border.all(color: AppColors.goldLight, width: 2)
                                              : (isToday
                                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                                  : null),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.gold.withValues(alpha: 0.4),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Day Label
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : null,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          ArabicNumbers.convert(day),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: (isToday || isSelected)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isToday
                                                ? AppColors.primary
                                                : (isSelected
                                                    ? (isDark ? Colors.white : Colors.black)
                                                    : (isDark ? Colors.white60 : Colors.black54)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Chart Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendDot(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFB8860B)],
                            ),
                            label: 'تم إنجاز الورد',
                          ),
                          const SizedBox(width: 14),
                          _buildLegendDot(
                            gradient: AppColors.primaryGradient,
                            label: 'تسبيح',
                          ),
                          const SizedBox(width: 14),
                          _buildLegendDot(
                            color: isDark ? Colors.white24 : Colors.black12,
                            label: 'لم يُسجل',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Set Daily Goal Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تحديد الورد اليومي للتسبيح 🎯',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${ArabicNumbers.convert(state.dailyGoal)} تسبيحة',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [33, 100, 300, 500, 1000].map((goalVal) {
                          final isSelected = state.dailyGoal == goalVal;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () {
                                  context.read<TasbeehBloc>().add(SetDailyGoalEvent(goalVal));
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.gold
                                          : (isDark ? Colors.white12 : Colors.black12),
                                    ),
                                  ),
                                  child: Text(
                                    ArabicNumbers.convert(goalVal),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : null,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Prophetic Hadith Quote
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories, color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'فضل المداومة على الذكر',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'قال رسول الله ﷺ: «أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ»',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildTopProgressBanner(TasbeehState state, bool isDark) {
    final progress =
        state.dailyGoal > 0 ? (state.todayCount / state.dailyGoal).clamp(0.0, 1.0) : 1.0;
    final isMet = state.todayCount >= state.dailyGoal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isMet
            ? const LinearGradient(
                colors: [Color(0xFF0F5A47), Color(0xFF072920)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ورد اليوم',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ArabicNumbers.convert(state.todayCount)} / ${ArabicNumbers.convert(state.dailyGoal)} تسبيحة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${ArabicNumbers.convert(state.streakDays)} يوم متتالي',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMet ? AppColors.gold : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isMet
                  ? 'تم إنجاز الورد اليومي بحمد الله! 🌟'
                  : 'متبقي ${ArabicNumbers.convert((state.dailyGoal - state.todayCount).clamp(0, 99999))} تسبيحة على إتمام الورد',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({
    Color? color,
    Gradient? gradient,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
