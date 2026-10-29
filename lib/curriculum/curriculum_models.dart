class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.units,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final List<Unit> units;

  int get totalLessons => units.fold(0, (sum, u) => sum + u.lessons.length);

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? 'menu_book',
        color: json['color'] as String? ?? '#4F46E5',
        units: (json['units'] as List)
            .map((u) => Unit.fromJson(u as Map<String, dynamic>))
            .toList(),
      );
}

class Unit {
  const Unit({required this.title, required this.lessons});

  final String title;
  final List<Lesson> lessons;

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        title: json['title'] as String,
        lessons: (json['lessons'] as List)
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

class Lesson {
  const Lesson({
    required this.title,
    required this.content,
    this.examples = const [],
    this.keyTerms = const {},
    this.quiz = const [],
    this.diagram,
  });

  final String title;
  final String content;
  final List<String> examples;
  final Map<String, String> keyTerms;
  final List<QuizQuestion> quiz;
  final String? diagram;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        title: json['title'] as String,
        content: json['content'] as String,
        examples: (json['examples'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        keyTerms: (json['keyTerms'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            const {},
        quiz: (json['quiz'] as List?)
                ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
                .toList() ??
            const [],
        diagram: json['diagram'] as String?,
      );
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correct;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        options:
            (json['options'] as List).map((o) => o as String).toList(),
        correct: json['correct'] as int,
        explanation: json['explanation'] as String,
      );
}
