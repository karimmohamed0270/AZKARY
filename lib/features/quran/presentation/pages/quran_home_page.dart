import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/quran_bloc.dart';
import '../../bloc/quran_event.dart';
import '../../bloc/quran_state.dart';
import 'surah_detail_page.dart';

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({super.key});

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.holyQuran),
        elevation: 0,
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          if (state.status == QuranStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<QuranBloc>().add(SearchQuranEvent(val));
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.searchSurah,
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              context.read<QuranBloc>().add(const SearchQuranEvent(''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      ),
                    ),
                  ),
                ),
              ),

              // Last Read Quick Action Card
              if (_searchController.text.isEmpty && state.lastReadSurahNumber > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurahDetailPage(
                                surahNumber: state.lastReadSurahNumber,
                                initialAyah: state.lastReadAyahNumber,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.menu_book, color: AppColors.goldLight, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      AppStrings.lastRead,
                                      style: TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'سورة ${state.lastReadSurahName}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'الآية ${ArabicNumbers.convert(state.lastReadAyahNumber)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  AppStrings.continueReading,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Search results or Tabs
              if (_searchController.text.isNotEmpty)
                Expanded(
                  child: _buildSearchResults(context, state),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primary,
                        labelColor: isDark ? AppColors.goldLight : AppColors.primary,
                        unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: '${AppStrings.surahs} (${ArabicNumbers.convert(state.surahs.length)})'),
                          Tab(text: '${AppStrings.bookmarks} (${ArabicNumbers.convert(state.bookmarks.length)})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSurahsList(context, state.filteredSurahs),
                            _buildBookmarksList(context, state.bookmarks),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSurahsList(BuildContext context, List surahs) {
    if (surahs.isEmpty) {
      return const Center(child: Text('لا توجد سور مطابقة'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                ArabicNumbers.convert(surah.number),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${surah.nameAr}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: surah.isMeccan
                        ? AppColors.gold.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    surah.isMeccan ? AppStrings.meccan : AppStrings.medinan,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: surah.isMeccan ? AppColors.goldDark : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${AppStrings.juz} ${ArabicNumbers.convert(surah.juz)} • ${ArabicNumbers.convert(surah.versesCount)} آية • صـ ${ArabicNumbers.convert(surah.page)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailPage(surahNumber: surah.number),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList(BuildContext context, List<Map<String, dynamic>> bookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'لا توجد إشارات مرجعية محفوظة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على أيقونة الإشارة المرجعية بجانب أي آية لحفظها هنا',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final surahNum = b['surah_number'] as int;
        final surahName = b['surah_name'] as String;
        final ayahNum = b['ayah_number'] as int;
        final ayahText = b['ayah_text'] as String? ?? '';

        return Card(
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة $surahName (الآية ${ArabicNumbers.convert(ayahNum)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
                  onPressed: () {
                    context.read<QuranBloc>().add(ToggleBookmarkEvent(
                          surahNumber: surahNum,
                          surahName: surahName,
                          ayahNumber: ayahNum,
                          ayahText: ayahText,
                        ));
                  },
                ),
              ],
            ),
            subtitle: Text(
              ayahText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailPage(
                    surahNumber: surahNum,
                    initialAyah: ayahNum,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, QuranState state) {
    final surahs = state.filteredSurahs;
    final ayahs = state.searchedAyahs;

    if (surahs.isEmpty && ayahs.isEmpty) {
      return const Center(child: Text('لا توجد نتائج بحث'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (surahs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('السور المطابقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...surahs.map((s) => Card(
                child: ListTile(
                  title: Text('سورة ${s.nameAr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.versesCount} آية • ${s.isMeccan ? AppStrings.meccan : AppStrings.medinan}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: s.number)),
                    );
                  },
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (ayahs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('الآيات المطابقة (${ArabicNumbers.convert(ayahs.length)}):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...ayahs.map((a) => Card(
                child: ListTile(
                  title: Text(
                    '${a['surah_name']} - الآية ${ArabicNumbers.convert(a['ayah_number'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      a['text'].toString(),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahDetailPage(
                          surahNumber: a['surah_number'] as int,
                          initialAyah: a['ayah_number'] as int,
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ],
    );
  }
}
