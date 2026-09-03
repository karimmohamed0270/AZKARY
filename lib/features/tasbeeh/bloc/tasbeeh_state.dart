import 'package:equatable/equatable.dart';

class TasbeehState extends Equatable {
  final int currentCount;
  final int currentCycle;
  final int targetCount; // 33, 99, 100, 1000, 0 (infinite)
  final int totalLifetimeCount;
  final String selectedDhikr;
  final List<String> availableDhikrs;
  final bool isSoundEnabled;
  final bool isHapticEnabled;

  const TasbeehState({
    this.currentCount = 0,
    this.currentCycle = 0,
    this.targetCount = 33,
    this.totalLifetimeCount = 0,
    this.selectedDhikr = 'سُبْحَانَ اللَّهِ',
    this.availableDhikrs = const [
      'سُبْحَانَ اللَّهِ',
      'الحَمْدُ لِلَّهِ',
      'لا إِلَهَ إِلا اللَّهُ',
      'اللَّهُ أَكْبَرُ',
      'أَسْتَغْفِرُ اللَّهَ',
      'لا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ',
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ العَظِيمِ',
      'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    ],
    this.isSoundEnabled = true,
    this.isHapticEnabled = true,
  });

  TasbeehState copyWith({
    int? currentCount,
    int? currentCycle,
    int? targetCount,
    int? totalLifetimeCount,
    String? selectedDhikr,
    List<String>? availableDhikrs,
    bool? isSoundEnabled,
    bool? isHapticEnabled,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      currentCycle: currentCycle ?? this.currentCycle,
      targetCount: targetCount ?? this.targetCount,
      totalLifetimeCount: totalLifetimeCount ?? this.totalLifetimeCount,
      selectedDhikr: selectedDhikr ?? this.selectedDhikr,
      availableDhikrs: availableDhikrs ?? this.availableDhikrs,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isHapticEnabled: isHapticEnabled ?? this.isHapticEnabled,
    );
  }

  @override
  List<Object?> get props => [
        currentCount,
        currentCycle,
        targetCount,
        totalLifetimeCount,
        selectedDhikr,
        availableDhikrs,
        isSoundEnabled,
        isHapticEnabled,
      ];
}
