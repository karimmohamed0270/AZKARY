class SurahModel {
  final int number;
  final String nameAr;
  final String nameEn;
  final String type; // 'meccan' or 'medinan'
  final int versesCount;
  final int page;
  final int juz;

  SurahModel({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.versesCount,
    required this.page,
    required this.juz,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      type: json['type'] as String,
      versesCount: json['verses_count'] as int,
      page: json['page'] as int,
      juz: json['juz'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name_ar': nameAr,
      'name_en': nameEn,
      'type': type,
      'verses_count': versesCount,
      'page': page,
      'juz': juz,
    };
  }

  bool get isMeccan => type.toLowerCase() == 'meccan';
}
