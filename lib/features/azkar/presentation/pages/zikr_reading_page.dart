import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/azkar_bloc.dart';
import '../../bloc/azkar_event.dart';
import '../../bloc/azkar_state.dart';

class ZikrReadingPage extends StatefulWidget {
  final String categoryName;

  const ZikrReadingPage({super.key, required this.categoryName});

  @override
  State<ZikrReadingPage> createState() => _ZikrReadingPageState();
}

class _ZikrReadingPageState extends State<ZikrReadingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AzkarBloc, AzkarState>(
      builder: (context, state) {
        final azkarList = state.currentCategoryAzkar;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (azkarList.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.categoryName)),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final allCompleted = azkarList.every((z) {
          final rem = state.zikrRemainingCounts[z.id] ?? z.count;
          return rem == 0;
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.categoryName),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.resetCounter,
                onPressed: () {
                  context.read<AzkarBloc>().add(ResetZikrProgressEvent(widget.categoryName));
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Progress Header (e.g. الذكر ٣ من 12)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الذكر ${ArabicNumbers.convert(_currentPage + 1)} من ${ArabicNumbers.convert(azkarList.length)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      allCompleted ? 'تم إتمام جميع الأذكار 🎉' : '',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Linear Page Indicator Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (azkarList.isNotEmpty) ? (_currentPage + 1) / azkarList.length : 0,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // PageView of Azkar Cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: azkarList.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    final zikr = azkarList[index];
                    final remaining = state.zikrRemainingCounts[zikr.id] ?? zikr.count;
                    final total = zikr.count;
                    final isDone = remaining == 0;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: isDone
                              ? const BorderSide(color: AppColors.gold, width: 2)
                              : BorderSide.none,
                        ),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            if (!isDone) {
                              context.read<AzkarBloc>().add(DecrementZikrCountEvent(zikr.id));
                              if (remaining == 1 && index < azkarList.length - 1) {
                                // Auto advance to next page after short delay
                                Future.delayed(const Duration(milliseconds: 350), () {
                                  if (mounted) {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                });
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Fadl / Source Badges
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (zikr.source.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          zikr.source,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),

                                    if (zikr.fadl.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: AppColors.goldDark, size: 22),
                                        tooltip: AppStrings.fadl,
                                        onPressed: () => _showFadlDialog(context, zikr.fadl, zikr.source),
                                      ),
                                  ],
                                ),

                                const Spacer(),

                                // Zikr Arabic Text
                                SingleChildScrollView(
                                  child: Text(
                                    zikr.text,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      height: 1.9,
                                      fontWeight: FontWeight.w600,
                                      color: isDone ? Colors.grey : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Interactive Circular Counter Button
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isDone ? AppColors.goldGradient : AppColors.primaryGradient,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isDone ? AppColors.goldDark : AppColors.primaryDark)
                                                  .withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: isDone
                                            ? const Icon(Icons.check, color: Colors.white, size: 40)
                                            : Text(
                                                ArabicNumbers.convert(remaining),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        isDone
                                            ? AppStrings.completed
                                            : 'اضغط للتسبيح (${ArabicNumbers.convert(total - remaining)} / ${ArabicNumbers.convert(total)})',
                                        style: TextStyle(
                                          color: isDone ? AppColors.goldDark : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Arrows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentPage > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentPage < azkarList.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
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

  void _showFadlDialog(BuildContext context, String fadl, String source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.stars, color: AppColors.gold),
            SizedBox(width: 8),
            Text(AppStrings.fadl, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fadl, style: const TextStyle(fontSize: 15, height: 1.6)),
            if (source.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'المصدر: $source',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
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
}
