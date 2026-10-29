import 'dart:convert';

class PathLesson {
  PathLesson({required this.title, this.isCompleted = false});
  final String title;
  final bool isCompleted;

  PathLesson copyWith({bool? isCompleted}) =>
      PathLesson(title: title, isCompleted: isCompleted ?? this.isCompleted);

  Map<String, dynamic> toMap() => {'title': title, 'isCompleted': isCompleted};

  factory PathLesson.fromMap(Map<String, dynamic> m) => PathLesson(
        title: m['title'] as String? ?? '',
        isCompleted: m['isCompleted'] as bool? ?? false,
      );
}

class PathUnit {
  PathUnit({required this.title, required this.lessons});
  final String title;
  final List<PathLesson> lessons;

  PathUnit copyWith({List<PathLesson>? lessons}) =>
      PathUnit(title: title, lessons: lessons ?? this.lessons);

  Map<String, dynamic> toMap() => {
        'title': title,
        'lessons': lessons.map((l) => l.toMap()).toList(),
      };

  factory PathUnit.fromMap(Map<String, dynamic> m) => PathUnit(
        title: m['title'] as String? ?? '',
        lessons: (m['lessons'] as List<dynamic>? ?? [])
            .map((l) => PathLesson.fromMap(l as Map<String, dynamic>))
            .toList(),
      );

  int get completedCount => lessons.where((l) => l.isCompleted).length;
  bool get isComplete =>
      lessons.isNotEmpty && completedCount == lessons.length;
}

class ParsedPath {
  ParsedPath({
    required this.topic,
    required this.title,
    required this.description,
    required this.units,
  });

  final String topic;
  final String title;
  final String description;
  final List<PathUnit> units;

  int get totalLessons => units.fold(0, (s, u) => s + u.lessons.length);
  int get completedLessons => units.fold(0, (s, u) => s + u.completedCount);
  double get progressFraction =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  String unitsToJson() =>
      jsonEncode(units.map((u) => u.toMap()).toList());

  static ParsedPath fromDb({
    required String topic,
    required String title,
    required String description,
    required String unitsJson,
  }) {
    final List<dynamic> raw =
        unitsJson.isEmpty ? [] : jsonDecode(unitsJson) as List<dynamic>;
    return ParsedPath(
      topic: topic,
      title: title,
      description: description,
      units:
          raw.map((m) => PathUnit.fromMap(m as Map<String, dynamic>)).toList(),
    );
  }
}
