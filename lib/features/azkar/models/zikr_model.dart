class ZikrModel {
  final int id;
  final String category;
  final String categoryId;
  final String text;
  final int count;
  final String fadl;
  final String source;

  ZikrModel({
    required this.id,
    required this.category,
    required this.categoryId,
    required this.text,
    required this.count,
    required this.fadl,
    required this.source,
  });

  factory ZikrModel.fromJson(Map<String, dynamic> json) {
    return ZikrModel(
      id: json['id'] as int,
      category: json['category'] as String,
      categoryId: json['category_id'] as String? ?? 'general',
      text: json['text'] as String,
      count: json['count'] as int? ?? 1,
      fadl: json['fadl'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'category_id': categoryId,
      'text': text,
      'count': count,
      'fadl': fadl,
      'source': source,
    };
  }
}
