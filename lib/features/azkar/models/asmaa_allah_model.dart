class AsmaaAllahModel {
  final int id;
  final String name;
  final String meaning;

  AsmaaAllahModel({
    required this.id,
    required this.name,
    required this.meaning,
  });

  factory AsmaaAllahModel.fromJson(Map<String, dynamic> json) {
    return AsmaaAllahModel(
      id: json['id'] as int,
      name: json['name'] as String,
      meaning: json['meaning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'meaning': meaning,
    };
  }
}
