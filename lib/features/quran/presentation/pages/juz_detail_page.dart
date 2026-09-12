import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../bloc/quran_bloc.dart';
import '../../bloc/quran_event.dart';
import '../../bloc/quran_state.dart';
import '../../data/quran_repository.dart';
import '../../models/ayah_model.dart';
import '../../models/juz_model.dart';
import '../../models/surah_model.dart';

class JuzDetailPage extends StatefulWidget {
  final int juzNumber;

  const JuzDetailPage({
    super.key,
    required this.juzNumber,
  });

  @override
  State<JuzDetailPage> createState() => _JuzDetailPageState();
}

class _JuzDetailPageState extends State<JuzDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final QuranRepository _repository = getIt<QuranRepository>();

  late int _currentJuzNumber;
  List<Map<String, dynamic>> _segments = [];
  bool _isLoading = true;
  int _readingMode = 0; // 0: App Theme, 1: Sepia Parchment, 2: Dark Night
  int? _selectedAyahNumber;
  int? _selectedSurahNumber;

  @override
  void initState() {
    super.initState();
    _currentJuzNumber = widget.juzNumber;
    _loadJuzData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJuzData() async {
    setState(() => _isLoading = true);
    final segments = await _repository.getJuzSurahSegments(_currentJuzNumber);
    if (mounted) {
      setState(() {
        _segments = segments;
        _isLoading = false;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNextJuz() {
    if (_currentJuzNumber < 30) {
      setState(() {
        _currentJuzNumber++;
      });
      _loadJuzData();
    }
  }

  void _goToPrevJuz() {
    if (_currentJuzNumber > 1) {
      setState(() {
        _currentJuzNumber--;
      });
      _loadJuzData();
    }
  }

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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Color pageBg;
        Color textColor;
        Color cardBg;
        Color borderOrnamentColor;

        if (_readingMode == 1) {
          pageBg = const Color(0xFFF5EEDC);
          textColor = const Color(0xFF2C2117);
          cardBg = const Color(0xFFFCF8EE);
          borderOrnamentColor = const Color(0xFFC7A868);
        } else if (_readingMode == 2) {
          pageBg = const Color(0xFF0D1614);
          textColor = const Color(0xFFE5EDE8);
          cardBg = const Color(0xFF14221D);
          borderOrnamentColor = AppColors.gold.withValues(alpha: 0.35);
        } else {
          pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFF6F8F7);
          textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          cardBg = isDark ? AppColors.cardDark : Colors.white;
          borderOrnamentColor = isDark
              ? AppColors.gold.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2);
        }

        final currentJuzInfo = JuzModel.allJuzs.firstWhere(
          (j) => j.number == _currentJuzNumber,
          orElse: () => JuzModel.allJuzs.first,
        );

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'الجزء ${ArabicNumbers.convert(_currentJuzNumber)} (${currentJuzInfo.name})',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
                onPressed: () {
                  setState(() {
                    _readingMode = (_readingMode + 1) % 3;
                  });
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    // Top Navigation Header between Juzs
                    _buildJuzHeaderCard(currentJuzInfo, isDark),

                    // Segments for each Surah in this Juz
                    for (final segment in _segments)
                      _buildSurahSegment(
                        context: context,
                        surah: segment['surah'] as SurahModel,
                        ayahs: segment['ayahs'] as List<AyahModel>,
                        state: state,
                        textColor: textColor,
                        cardBg: cardBg,
                        borderOrnamentColor: borderOrnamentColor,
                        isDark: isDark,
                      ),

                    // --------------------------------------------------------
                    // CELEBRATORY JUZ COMPLETION CARD (عند نهاية كل جزء)
                    // --------------------------------------------------------
                    _buildJuzCompletionCard(context, currentJuzInfo),
                    const SizedBox(height: 30),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildJuzHeaderCard(JuzModel juz, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.goldLight, size: 20),
                tooltip: 'الجزء السابق',
                onPressed: _currentJuzNumber > 1 ? _goToPrevJuz : null,
              ),
              Column(
                children: [
                  Text(
                    'الجزء ${ArabicNumbers.convert(juz.number)}: ${juz.name}',
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${juz.startSurahName} (آية ${ArabicNumbers.convert(juz.startAyah)}) إلى ${juz.endSurahName} (آية ${ArabicNumbers.convert(juz.endAyah)})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: AppColors.goldLight, size: 20),
                tooltip: 'الجزء التالي',
                onPressed: _currentJuzNumber < 30 ? _goToNextJuz : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahSegment({
    required BuildContext context,
    required SurahModel surah,
    required List<AyahModel> ayahs,
    required QuranState state,
    required Color textColor,
    required Color cardBg,
    required Color borderOrnamentColor,
    required bool isDark,
  }) {
    final bool startsAtFirstAyah = ayahs.isNotEmpty && ayahs.first.numberInSurah == 1;
    final bool isAlFatiha = surah.number == 1;
    final bool isAtTawbah = surah.number == 9;

    final AyahModel? fatihaBismillah = isAlFatiha && ayahs.isNotEmpty ? ayahs.first : null;
    final List<AyahModel> continuousAyahs =
        isAlFatiha && ayahs.isNotEmpty ? ayahs.sublist(1) : ayahs;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderOrnamentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surah Header Banner inside segment
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    startsAtFirstAyah
                        ? 'سورة ${surah.nameAr}'
                        : 'تابع سورة ${surah.nameAr} (من الآية ${ArabicNumbers.convert(ayahs.first.numberInSurah)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${surah.isMeccan ? AppStrings.meccan : AppStrings.medinan} • ${ArabicNumbers.convert(ayahs.length)} آية بالقسم',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Bismillah for surahs starting at ayah 1
            if (startsAtFirstAyah && !isAlFatiha && !isAtTawbah)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                alignment: Alignment.center,
                child: Text(
                  AppStrings.bismillah,
                  style: TextStyle(
                    fontSize: (state.fontSize * 1.05).clamp(20.0, 32.0),
                    fontWeight: FontWeight.bold,
                    color: _readingMode == 1 ? const Color(0xFF6B4518) : AppColors.primary,
                  ),
                ),
              ),

            // Surah 1 Bismillah as Verse 1
            if (isAlFatiha && fatihaBismillah != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${fatihaBismillah.text.replaceAll('\ufeff', '').trim()} ',
                          style: TextStyle(
                            fontSize: state.fontSize * 1.05,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const TextSpan(
                          text: '﴿١﴾',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Continuous text of ayahs in this segment
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final ayah in continuousAyahs) ...[
                      TextSpan(
                        text: '${_getCleanAyahText(surah.number, ayah.numberInSurah, ayah.text)} ',
                        style: TextStyle(
                          fontSize: state.fontSize,
                          height: 2.3,
                          color: (_selectedAyahNumber == ayah.numberInSurah &&
                                  _selectedSurahNumber == surah.number)
                              ? AppColors.primary
                              : textColor,
                          backgroundColor: (_selectedAyahNumber == ayah.numberInSurah &&
                                  _selectedSurahNumber == surah.number)
                              ? AppColors.primary.withValues(alpha: 0.18)
                              : (state.bookmarks.any((b) =>
                                      b['surah_number'] == surah.number &&
                                      b['ayah_number'] == ayah.numberInSurah)
                                  ? AppColors.gold.withValues(alpha: 0.22)
                                  : null),
                          fontWeight: (_selectedAyahNumber == ayah.numberInSurah &&
                                  _selectedSurahNumber == surah.number)
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showAyahActionSheet(context, ayah, surah),
                      ),
                      TextSpan(
                        text: '﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ ',
                        style: TextStyle(
                          fontSize: state.fontSize * 0.88,
                          height: 2.3,
                          color: state.bookmarks.any((b) =>
                                  b['surah_number'] == surah.number &&
                                  b['ayah_number'] == ayah.numberInSurah)
                              ? AppColors.gold
                              : (_readingMode == 1 ? const Color(0xFF8C6228) : AppColors.primary),
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showAyahActionSheet(context, ayah, surah),
                      ),
                    ],
                  ],
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -----------------------------------------------------------------------
  /// CELEBRATORY JUZ COMPLETION CARD (إشارة نهاية الجزء)
  /// -----------------------------------------------------------------------
  Widget _buildJuzCompletionCard(BuildContext context, JuzModel juz) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F5A47), Color(0xFF072920)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Islamic Emblem
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.goldLight,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),

          // Completion Title
          Text(
            'تم بحمد الله ختام الجزء ${ArabicNumbers.convert(juz.number)}',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Congratulatory message
          const Text(
            'هنيئاً لك إتمام قراءة هذا الجزء المبارك من كتاب الله تعالى\nتقبل الله طاعتكم وجعل القرآن الكريم ربيع قلوبكم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Quranic Verse decoration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '﴿ وَقُل رَّبِّ زِدْنِي عِلْمًا ﴾',
              style: TextStyle(
                color: AppColors.goldLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            children: [
              if (_currentJuzNumber < 30)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, color: Colors.black),
                    label: Text(
                      'الجزء التالي (${ArabicNumbers.convert(_currentJuzNumber + 1)})',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _goToNextJuz,
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.celebration, color: Colors.black),
                    label: const Text(
                      'دعاء ختم القرآن الكريم',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _showKhatmDua(context),
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('فهرس الأجزاء'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showKhatmDua(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: AppColors.gold),
            SizedBox(width: 10),
            Text('دعاء ختم القرآن الكريم', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'اللَّهُمَّ ارْحَمْنِي بالقُرْآنِ وَاجْعَلهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً.\n\n'
            'اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.\n\n'
            'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي.',
            style: TextStyle(fontSize: 16, height: 1.8),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('آمين يا رب العالمين', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAyahActionSheet(BuildContext context, AyahModel ayah, SurahModel surah) {
    setState(() {
      _selectedAyahNumber = ayah.numberInSurah;
      _selectedSurahNumber = surah.number;
    });

    final isBookmarked = context.read<QuranBloc>().state.bookmarks.any(
          (b) => b['surah_number'] == surah.number && b['ayah_number'] == ayah.numberInSurah,
        );

    final cleanText = _getCleanAyahText(surah.number, ayah.numberInSurah, ayah.text);
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
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سورة ${surah.nameAr} - الآية ${ArabicNumbers.convert(ayah.numberInSurah)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: sheetTextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey,
                    onPressed: () => Navigator.pop(bContext),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
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
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.gold,
                      label: isBookmarked ? 'إزالة الفاصل' : 'حفظ فاصل',
                      textColor: sheetTextColor,
                      onTap: () {
                        context.read<QuranBloc>().add(ToggleBookmarkEvent(
                              surahNumber: surah.number,
                              surahName: surah.nameAr,
                              ayahNumber: ayah.numberInSurah,
                              ayahText: cleanText,
                            ));
                        Navigator.pop(bContext);
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
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.history_rounded,
                      color: AppColors.primary,
                      label: 'موضع القراءة',
                      textColor: sheetTextColor,
                      onTap: () {
                        context.read<QuranBloc>().add(SaveLastReadEvent(
                              surahNumber: surah.number,
                              surahName: surah.nameAr,
                              ayahNumber: ayah.numberInSurah,
                            ));
                        Navigator.pop(bContext);
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
                  Expanded(
                    child: _buildActionBtn(
                      icon: Icons.copy_rounded,
                      color: Colors.blueGrey,
                      label: 'نسخ الآية',
                      textColor: sheetTextColor,
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text:
                              '$cleanText ﴿${ArabicNumbers.convert(ayah.numberInSurah)}﴾ [سورة ${surah.nameAr}]',
                        ));
                        Navigator.pop(bContext);
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
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedAyahNumber = null;
          _selectedSurahNumber = null;
        });
      }
    });
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
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

  void _showFontSizeSheet(BuildContext context, double currentSize) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                        setSheetState(() => currentSize = val);
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
        ),
      ),
    );
  }
}
