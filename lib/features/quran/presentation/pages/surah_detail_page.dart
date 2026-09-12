import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/quran_bloc.dart';
import '../../bloc/quran_event.dart';
import '../../bloc/quran_state.dart';
import '../../models/ayah_model.dart';
import '../../models/surah_model.dart';

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
  int _readingMode = 0; // 0: App Theme, 1: Sepia Parchment, 2: Dark Night
  bool _isContinuous = true; // True: Continuous Mushaf text ("ورا بعض"), False: Cards
  int? _selectedAyahNumber;

  @override
  void initState() {
    super.initState();
    _selectedAyahNumber = widget.initialAyah;
    context.read<QuranBloc>().add(LoadSurahDetailEvent(widget.surahNumber));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Clean Ayah text to remove BOM and avoid duplicate Bismillah in Ayah 1 for Surahs 2..114
  String _getCleanAyahText(int surahNum, int ayahNum, String rawText) {
    String text = rawText.replaceAll('\ufeff', '').trim();
    if (surahNum != 1 && surahNum != 9 && ayahNum == 1) {
      const prefixes = [
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'بِّسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      ];
      for (final prefix in prefixes) {
        if (text.startsWith(prefix)) {
          text = text.substring(prefix.length).trim();
          break;
        }
      }
    }
    return text;
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
        Color borderOrnamentColor;

        if (_readingMode == 1) {
          // Sepia Parchment (Mushaf paper style)
          pageBg = const Color(0xFFF5EEDC);
          textColor = const Color(0xFF2C2117);
          cardBg = const Color(0xFFFCF8EE);
          borderOrnamentColor = const Color(0xFFC7A868);
        } else if (_readingMode == 2) {
          // Dark Night
          pageBg = const Color(0xFF0D1614);
          textColor = const Color(0xFFE5EDE8);
          cardBg = const Color(0xFF14221D);
          borderOrnamentColor = AppColors.gold.withValues(alpha: 0.35);
        } else {
          // Default Theme (Light / Dark)
          pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFF6F8F7);
          textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          cardBg = isDark ? AppColors.cardDark : Colors.white;
          borderOrnamentColor = isDark
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2);
        }

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              surah != null ? 'سورة ${surah.nameAr}' : 'القرآن الكريم',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            actions: [
              // Toggle between Continuous Mushaf View and Cards View
              IconButton(
                icon: Icon(
                  _isContinuous ? Icons.view_agenda_outlined : Icons.menu_book_rounded,
                  color: textColor,
                ),
                tooltip: _isContinuous ? 'عرض كبطاقات منفصلة' : 'عرض متصل (المصحف)',
                onPressed: () {
                  setState(() {
                    _isContinuous = !_isContinuous;
                  });
                },
              ),
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
              : _isContinuous
                  ? _buildContinuousMushafView(
                      context: context,
                      surah: surah,
                      ayahs: ayahs,
                      state: state,
                      textColor: textColor,
                      cardBg: cardBg,
                      borderOrnamentColor: borderOrnamentColor,
                      isDark: isDark,
                    )
                  : _buildCardsView(
                      context: context,
                      surah: surah,
                      ayahs: ayahs,
                      state: state,
                      textColor: textColor,
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
        );
      },
    );
  }

  /// -------------------------------------------------------------
  /// CONTINUOUS MUSHAF VIEW ("الآيات ورا بعض عادى")
  /// -------------------------------------------------------------
  Widget _buildContinuousMushafView({
    required BuildContext context,
    required SurahModel? surah,
    required List<AyahModel> ayahs,
    required QuranState state,
    required Color textColor,
    required Color cardBg,
    required Color borderOrnamentColor,
    required bool isDark,
  }) {
    // Check if Surah 1 (Al-Fatiha)
    final bool isAlFatiha = widget.surahNumber == 1;
    final bool isAtTawbah = widget.surahNumber == 9;

    // For Al-Fatiha: Ayah 1 is Bismillah itself.
    // For others (2..114 except 9): Bismillah is shown in the header ornament.
    final AyahModel? fatihaBismillahAyah = isAlFatiha && ayahs.isNotEmpty ? ayahs[0] : null;
    final List<AyahModel> continuousAyahs =
        isAlFatiha && ayahs.isNotEmpty ? ayahs.sublist(1) : ayahs;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        // 1. Top Surah Information Banner
        _buildSurahBanner(surah, isDark),

        // 2. Mushaf Page Frame
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderOrnamentColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Calligraphic Bismillah for Surahs 2..114 (except At-Tawbah)
                if (!isAlFatiha && !isAtTawbah)
                  _buildBismillahHeader(textColor, borderOrnamentColor, state.fontSize),

                // For Al-Fatiha: Centered Bismillah as Verse 1 with Ayah End Mark ﴿١﴾
                if (isAlFatiha && fatihaBismillahAyah != null)
                  _buildFatihaBismillahVerse(
                    context: context,
                    ayah: fatihaBismillahAyah,
                    surah: surah,
                    state: state,
                    textColor: textColor,
                  ),

                if (isAlFatiha && fatihaBismillahAyah != null)
                  const SizedBox(height: 12),

                // The continuous flowing text containing all remaining ayahs
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text.rich(
                    TextSpan(
                      children: _buildContinuousSpans(
                        context: context,
                        ayahs: continuousAyahs,
                        surah: surah,
                        state: state,
                        textColor: textColor,
                      ),
                    ),
                    textAlign: ayahs.length <= 6 ? TextAlign.center : TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Surah Conclusion & Info Footer
        _buildSurahFooter(surah, textColor),
      ],
    );
  }

  /// Builds the spans for continuous text flow with interactive ayah taps and marks
  List<InlineSpan> _buildContinuousSpans({
    required BuildContext context,
    required List<AyahModel> ayahs,
    required SurahModel? surah,
    required QuranState state,
    required Color textColor,
  }) {
    final List<InlineSpan> spans = [];

    for (final ayah in ayahs) {
      final cleanText = _getCleanAyahText(widget.surahNumber, ayah.numberInSurah, ayah.text);
      final isBookmarked = state.bookmarks.any(
        (b) => b['surah_number'] == widget.surahNumber && b['ayah_number'] == ayah.numberInSurah,
      );
      final isSelected = _selectedAyahNumber == ayah.numberInSurah;

      // Ayah Text Span
      spans.add(
        TextSpan(
          text: '$cleanText ',
          style: TextStyle(
            fontSize: state.fontSize,
            height: 2.3,
            color: isSelected ? AppColors.primary : textColor,
            backgroundColor: isSelected
                ? AppColors.primary.withValues(alpha: 0.16)
                : (isBookmarked ? AppColors.gold.withValues(alpha: 0.22) : null),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showAyahActionSheet(context, ayah, surah, cleanText, isBookmarked),
        ),
      );

      // Ayah Number Bracket Span ﴿١﴾
      spans.add(
        TextSpan(
          text: '﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ ',
          style: TextStyle(
            fontSize: state.fontSize * 0.88,
            height: 2.3,
            color: isBookmarked
                ? AppColors.gold
                : (_readingMode == 1 ? const Color(0xFF8C6228) : AppColors.primary),
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _showAyahActionSheet(context, ayah, surah, cleanText, isBookmarked),
        ),
      );
    }

    return spans;
  }

  /// Centered Bismillah for Surah Al-Fatiha (Ayah 1)
  Widget _buildFatihaBismillahVerse({
    required BuildContext context,
    required AyahModel ayah,
    required SurahModel? surah,
    required QuranState state,
    required Color textColor,
  }) {
    final cleanText = ayah.text.replaceAll('\ufeff', '').trim();
    final isBookmarked = state.bookmarks.any(
      (b) => b['surah_number'] == 1 && b['ayah_number'] == 1,
    );
    final isSelected = _selectedAyahNumber == 1;

    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAyahActionSheet(context, ayah, surah, cleanText, isBookmarked),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : (isBookmarked ? AppColors.gold.withValues(alpha: 0.16) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$cleanText ',
                  style: TextStyle(
                    fontSize: state.fontSize * 1.05,
                    height: 2.2,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : textColor,
                  ),
                ),
                TextSpan(
                  text: '﴿١﴾',
                  style: TextStyle(
                    fontSize: state.fontSize * 0.9,
                    color: isBookmarked ? AppColors.gold : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }

  /// Calligraphic Bismillah Header with decorative Islamic motifs for Surahs 2..114
  Widget _buildBismillahHeader(Color textColor, Color ornamentColor, double fontSize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: ornamentColor, width: 1.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 18, color: ornamentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppStrings.bismillah,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (fontSize * 1.05).clamp(20.0, 32.0),
                fontWeight: FontWeight.bold,
                color: _readingMode == 1 ? const Color(0xFF6B4518) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.star_border_rounded, size: 18, color: ornamentColor),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// CARDS VIEW (Optional alternative mode with fixed spacing)
  /// -------------------------------------------------------------
  Widget _buildCardsView({
    required BuildContext context,
    required SurahModel? surah,
    required List<AyahModel> ayahs,
    required QuranState state,
    required Color textColor,
    required Color cardBg,
    required bool isDark,
  }) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSurahBanner(surah, isDark);
        }

        final ayahIndex = index - 1;
        final ayah = ayahs[ayahIndex];
        final cleanText = _getCleanAyahText(widget.surahNumber, ayah.numberInSurah, ayah.text);
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
                : BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
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
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked ? AppColors.gold : Colors.grey,
                            size: 22,
                          ),
                          tooltip: isBookmarked ? 'إزالة الفاصل' : 'إضافة فاصل',
                          onPressed: () {
                            context.read<QuranBloc>().add(ToggleBookmarkEvent(
                                  surahNumber: widget.surahNumber,
                                  surahName: surah?.nameAr ?? '',
                                  ayahNumber: ayah.numberInSurah,
                                  ayahText: cleanText,
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
                                content: Text('تم حفظ موضع القراءة'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                          tooltip: 'نسخ الآية',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: '$cleanText ﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ [سورة ${surah?.nameAr ?? ""}]',
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

                // Ayah Text aligned properly without unnatural justification spaces
                Text(
                  cleanText,
                  textAlign: cleanText.length < 50 ? TextAlign.center : TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: state.fontSize,
                    color: textColor,
                    height: 2.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// -------------------------------------------------------------
  /// SURAH BANNER (Header with Surah Information)
  /// -------------------------------------------------------------
  Widget _buildSurahBanner(SurahModel? surah, bool isDark) {
    if (surah == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
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
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Surah Footer decoration at end of surah
  Widget _buildSurahFooter(SurahModel? surah, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: textColor.withValues(alpha: 0.2)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  '◈ ◈ ◈',
                  style: TextStyle(color: AppColors.gold, fontSize: 14),
                ),
              ),
              Container(width: 40, height: 1, color: textColor.withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'نهاية سورة ${surah?.nameAr ?? ""}',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// AYAH ACTION BOTTOM SHEET (When tapping on any Ayah)
  /// -------------------------------------------------------------
  void _showAyahActionSheet(
    BuildContext context,
    AyahModel ayah,
    SurahModel? surah,
    String cleanText,
    bool isBookmarked,
  ) {
    setState(() {
      _selectedAyahNumber = ayah.numberInSurah;
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = _readingMode == 1
        ? const Color(0xFFF7F1E1)
        : (_readingMode == 2
            ? const Color(0xFF162520)
            : (isDark ? AppColors.cardDark : Colors.white));
    final sheetTextColor = _readingMode == 1
        ? const Color(0xFF2C2117)
        : (_readingMode == 2 ? const Color(0xFFE5EDE8) : (isDark ? Colors.white : Colors.black87));

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header: Surah and Ayah Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سورة ${surah?.nameAr ?? ""} - الآية ${ArabicNumbers.convert(ayah.numberInSurah)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sheetTextColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.grey,
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ayah Preview Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _readingMode == 1
                            ? const Color(0xFFEFE7D3)
                            : (_readingMode == 2
                                ? const Color(0xFF0F1B17)
                                : (isDark
                                    ? AppColors.cardDarkSecondary
                                    : AppColors.backgroundLight)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '$cleanText ﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: sheetTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons Row
                    Row(
                      children: [
                        // 1. Bookmark Action
                        Expanded(
                          child: _buildActionButton(
                            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            iconColor: AppColors.gold,
                            label: isBookmarked ? 'إزالة الفاصل' : 'حفظ فاصل',
                            textColor: sheetTextColor,
                            onTap: () {
                              context.read<QuranBloc>().add(ToggleBookmarkEvent(
                                    surahNumber: widget.surahNumber,
                                    surahName: surah?.nameAr ?? '',
                                    ayahNumber: ayah.numberInSurah,
                                    ayahText: cleanText,
                                  ));
                              Navigator.pop(bottomSheetContext);
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
                        ),
                        const SizedBox(width: 10),

                        // 2. Last Read Action
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.history_rounded,
                            iconColor: AppColors.primary,
                            label: 'موضع القراءة',
                            textColor: sheetTextColor,
                            onTap: () {
                              context.read<QuranBloc>().add(SaveLastReadEvent(
                                    surahNumber: widget.surahNumber,
                                    surahName: surah?.nameAr ?? '',
                                    ayahNumber: ayah.numberInSurah,
                                  ));
                              Navigator.pop(bottomSheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ موضع القراءة'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 3. Copy Ayah Action
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.copy_rounded,
                            iconColor: Colors.blueGrey,
                            label: 'نسخ الآية',
                            textColor: sheetTextColor,
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text:
                                    '$cleanText ﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ [سورة ${surah?.nameAr ?? ""}]',
                              ));
                              Navigator.pop(bottomSheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الآية إلى الحافظة'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedAyahNumber = null;
        });
      }
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                          max: 38.0,
                          divisions: 11,
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
