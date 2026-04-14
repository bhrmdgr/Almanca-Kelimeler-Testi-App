class WordModel {
  final String de;
  final String tr;
  final String type;
  final String level;

  WordModel({
    required this.de,
    required this.tr,
    required this.type,
    required this.level,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      de: json['de'] ?? '',
      tr: json['tr'] ?? '',
      type: json['type'] ?? '',
      level: json['level'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'de': de,
      'tr': tr,
      'type': type,
      'level': level,
    };
  }
}

class QuizSettings {
  int questionCount;
  String selectedLevel;
  String selectedType;

  QuizSettings({
    this.questionCount = 10,
    this.selectedLevel = 'A1',
    this.selectedType = 'all',
  });
}