class AyahModel {
  final int number;
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;

  AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      number: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? (json['number_in_surah'] as int? ?? 0),
      text: json['text'] as String? ?? '',
      juz: json['juz'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'numberInSurah': numberInSurah,
      'text': text,
      'juz': juz,
      'page': page,
    };
  }
}
