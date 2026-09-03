import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/azkar_bloc.dart';
import '../../bloc/azkar_event.dart';
import '../../bloc/azkar_state.dart';
import 'asmaa_allah_page.dart';
import 'zikr_reading_page.dart';

class AzkarHomePage extends StatelessWidget {
  const AzkarHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.azkarCategories),
      ),
      body: BlocBuilder<AzkarBloc, AzkarState>(
        builder: (context, state) {
          if (state.status == AzkarStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final categories = state.categories;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 99 Names of Allah Banner
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldDark.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AsmaaAllahPage()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  AppStrings.asmaaAllah,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '٩٩ اسماً مع معانيها وفضلها',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.black87, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'أذكار المسلم اليومية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final name = cat['category'] as String;
                  final count = cat['count'] as int;
                  final catId = cat['category_id'] as String;

                  return _buildCategoryCard(context, name, count, catId);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    int count,
    String catId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _getIconData(catId);

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.read<AzkarBloc>().add(LoadAzkarByCategoryEvent(name));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ZikrReadingPage(categoryName: name),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDarkSecondary
                      : AppColors.primaryContainer.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: AppColors.primary, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ArabicNumbers.convert(count)} أذكار',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String catId) {
    switch (catId) {
      case 'sabah':
        return Icons.wb_sunny;
      case 'masaa':
        return Icons.nights_stay;
      case 'after_prayer':
        return Icons.mosque;
      case 'sleep':
        return Icons.bedtime;
      case 'waking':
        return Icons.alarm;
      case 'quranic_duas':
        return Icons.menu_book;
      case 'prophetic_duas':
        return Icons.favorite;
      case 'ruqyah':
        return Icons.security;
      default:
        return Icons.auto_stories;
    }
  }
}
