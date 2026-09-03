import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/quran_bloc.dart';
import '../../bloc/quran_event.dart';
import '../../bloc/quran_state.dart';

class SurahDetailPage extends StatefulWidget {
  final int surahNumber;
  final int? initialAyah;

  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  final ScrollController _scrollController = ScrollController();
  int _readingMode = 0; // 0: Default (App Theme), 1: Sepia Parchment, 2: Dark Night

  @override
  void initState() {
    super.initState();
    context.read<QuranBloc>().add(LoadSurahDetailEvent(widget.surahNumber));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        final surah = state.currentSurah;
        final ayahs = state.currentSurahAyahs;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Color pageBg;
        Color textColor;
        Color cardBg;

        if (_readingMode == 1) {
          // Sepia Parchment
          pageBg = const Color(0xFFF6F0DF);
          textColor = const Color(0xFF2C221E);
          cardBg = const Color(0xFFFAF6EB);
        } else if (_readingMode == 2) {
          // Dark Night
          pageBg = const Color(0xFF0F1715);
          textColor = const Color(0xFFE8EFEA);
          cardBg = const Color(0xFF182420);
        } else {
          pageBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
          textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          cardBg = isDark ? AppColors.cardDark : Colors.white;
        }

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            foregroundColor: textColor,
            title: Text(
              surah != null ? 'سورة ${surah.nameAr}' : 'القرآن الكريم',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_size),
                tooltip: 'تغيير حجم الخط',
                onPressed: () => _showFontSizeSheet(context, state.fontSize),
              ),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'وضع القراءة',
                onPressed: _cycleReadingMode,
              ),
            ],
          ),
          body: ayahs.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ayahs.length + 1, // +1 for Header Banner & Bismillah
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSurahBanner(surah, isDark);
                    }

                    final ayahIndex = index - 1;
                    final ayah = ayahs[ayahIndex];
                    final isBookmarked = state.bookmarks.any(
                      (b) => b['surah_number'] == widget.surahNumber && b['ayah_number'] == ayah.numberInSurah,
                    );

                    return Card(
                      color: cardBg,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isBookmarked
                            ? const BorderSide(color: AppColors.gold, width: 1.5)
                            : BorderSide(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ayah Action Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Ayah Number Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'الآية ${ArabicNumbers.convert(ayah.numberInSurah)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Bookmark button
                                    IconButton(
                                      icon: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        color: isBookmarked ? AppColors.gold : Colors.grey,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        context.read<QuranBloc>().add(ToggleBookmarkEvent(
                                              surahNumber: widget.surahNumber,
                                              surahName: surah?.nameAr ?? '',
                                              ayahNumber: ayah.numberInSurah,
                                              ayahText: ayah.text,
                                            ));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isBookmarked
                                                  ? AppStrings.bookmarkRemoved
                                                  : AppStrings.bookmarkAdded,
                                            ),
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                    // Save as last read
                                    IconButton(
                                      icon: const Icon(Icons.history, color: Colors.grey, size: 22),
                                      tooltip: 'حفظ كآخر قراءة',
                                      onPressed: () {
                                        context.read<QuranBloc>().add(SaveLastReadEvent(
                                              surahNumber: widget.surahNumber,
                                              surahName: surah?.nameAr ?? '',
                                              ayahNumber: ayah.numberInSurah,
                                            ));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم حفظ مكان القراءة'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                    // Copy text button
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                                      tooltip: 'نسخ الآية',
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                          text: '${ayah.text} ﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ [سورة ${surah?.nameAr ?? ""}]',
                                        ));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم نسخ الآية إلى الحافظة'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            const SizedBox(height: 8),

                            // Ayah Text
                            Text(
                              ayah.text,
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: state.fontSize,
                                color: textColor,
                                height: 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSurahBanner(dynamic surah, bool isDark) {
    if (surah == null) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'سورة ${surah.nameAr}',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${surah.isMeccan ? AppStrings.meccan : AppStrings.medinan} • ${ArabicNumbers.convert(surah.versesCount)} آية • ${AppStrings.juz} ${ArabicNumbers.convert(surah.juz)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Bismillah Banner (All surahs except At-Tawbah)
        if (widget.surahNumber != 9)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: const Text(
              AppStrings.bismillah,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  void _cycleReadingMode() {
    setState(() {
      _readingMode = (_readingMode + 1) % 3;
    });
  }

  void _showFontSizeSheet(BuildContext context, double currentSize) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppStrings.fontSize,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('أ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Slider(
                          value: currentSize,
                          min: 16.0,
                          max: 36.0,
                          divisions: 10,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setSheetState(() {
                              currentSize = val;
                            });
                            context.read<QuranBloc>().add(ChangeFontSizeEvent(val));
                          },
                        ),
                      ),
                      const Text('أ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${ArabicNumbers.convert(currentSize.toInt())} نقطة',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
