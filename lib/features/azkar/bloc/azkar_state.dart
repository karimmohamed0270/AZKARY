import 'package:equatable/equatable.dart';
import '../models/asmaa_allah_model.dart';
import '../models/zikr_model.dart';

enum AzkarStatus { initial, loading, loaded, error }

class AzkarState extends Equatable {
  final AzkarStatus status;
  final List<Map<String, dynamic>> categories;
  final List<ZikrModel> currentCategoryAzkar;
  final Map<int, int> zikrRemainingCounts; // Maps zikrId -> remaining count
  final List<AsmaaAllahModel> asmaaAllah;
  final String? selectedCategory;
  final String? errorMessage;

  const AzkarState({
    this.status = AzkarStatus.initial,
    this.categories = const [],
    this.currentCategoryAzkar = const [],
    this.zikrRemainingCounts = const {},
    this.asmaaAllah = const [],
    this.selectedCategory,
    this.errorMessage,
  });

  AzkarState copyWith({
    AzkarStatus? status,
    List<Map<String, dynamic>>? categories,
    List<ZikrModel>? currentCategoryAzkar,
    Map<int, int>? zikrRemainingCounts,
    List<AsmaaAllahModel>? asmaaAllah,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return AzkarState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      currentCategoryAzkar: currentCategoryAzkar ?? this.currentCategoryAzkar,
      zikrRemainingCounts: zikrRemainingCounts ?? this.zikrRemainingCounts,
      asmaaAllah: asmaaAllah ?? this.asmaaAllah,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        currentCategoryAzkar,
        zikrRemainingCounts,
        asmaaAllah,
        selectedCategory,
        errorMessage,
      ];
}
