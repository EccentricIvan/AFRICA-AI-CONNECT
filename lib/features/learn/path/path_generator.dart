import 'dart:convert';
import '../../../ai_core/inference/inference_engine.dart';
import '../../../db/otic_database.dart';
import 'path_models.dart';

/// Generates a structured learning path for a topic using the local AI model.
/// Falls back to a hand-crafted curriculum if the model returns invalid JSON.
class PathGenerator {
  PathGenerator({required this._engine});

  final InferenceEngine _engine;

  Future<ParsedPath> generate({
    required String topic,
    required Student student,
    int currentMasteryLevel = 0,
  }) async {
    final prompt = _buildPrompt(topic, student, currentMasteryLevel);
    String raw = '';
    try {
      raw = await _engine.generate(
        prompt: prompt,
        maxTokens: 600,
        temperature: 0.3, // low temp for structured output
      );
      return _parse(topic, raw);
    } catch (_) {
      return _fallback(topic, student);
    }
  }

  String _buildPrompt(String topic, Student student, int mastery) {
    final level = mastery < 20
        ? 'complete beginner'
        : mastery < 50
            ? 'some basic knowledge'
            : 'intermediate learner';
    final grade = student.grade ?? 'secondary school';

    return '''You are an expert curriculum designer. Create a learning path as valid JSON.

Student: ${student.name}, $grade, $level in $topic.

Respond ONLY with this JSON format (no explanation, no markdown):
{
  "title": "Learning path title",
  "description": "One sentence about what they will achieve.",
  "units": [
    {
      "title": "Unit title",
      "lessons": [
        {"title": "Lesson title", "isCompleted": false}
      ]
    }
  ]
}

Rules:
- Exactly 4 units
- Exactly 3 lessons per unit (12 lessons total)
- Progress from beginner to confident user of $topic
- Keep titles short (under 8 words each)
- No markdown, no code blocks, ONLY raw JSON

Topic: $topic''';
  }

  ParsedPath _parse(String topic, String raw) {
    // Extract JSON object from the model output
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1) throw const FormatException('No JSON found');

    final jsonStr = raw.substring(start, end + 1);
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;

    final units = (data['units'] as List<dynamic>? ?? [])
        .map((u) => PathUnit.fromMap(u as Map<String, dynamic>))
        .toList();

    if (units.isEmpty) throw const FormatException('Empty units');

    return ParsedPath(
      topic: topic,
      title: data['title'] as String? ?? '$topic Learning Path',
      description: data['description'] as String? ?? 'Master $topic step by step.',
      units: units,
    );
  }

  /// Hand-crafted fallback when AI output is unparseable.
  ParsedPath _fallback(String topic, Student student) {
    final units = [
      PathUnit(title: 'Foundations', lessons: [
        PathLesson(title: 'What is $topic?'),
        PathLesson(title: 'Key concepts and terms'),
        PathLesson(title: 'Why $topic matters'),
      ]),
      PathUnit(title: 'Core Knowledge', lessons: [
        PathLesson(title: 'Main principles of $topic'),
        PathLesson(title: 'How $topic works in practice'),
        PathLesson(title: 'Common examples and cases'),
      ]),
      PathUnit(title: 'Application', lessons: [
        PathLesson(title: 'Solving problems with $topic'),
        PathLesson(title: 'Real-world scenarios'),
        PathLesson(title: 'Hands-on practice'),
      ]),
      PathUnit(title: 'Mastery', lessons: [
        PathLesson(title: 'Advanced concepts'),
        PathLesson(title: 'Teaching $topic to others'),
        PathLesson(title: 'Final review and self-test'),
      ]),
    ];
    return ParsedPath(
      topic: topic,
      title: '$topic — Complete Path',
      description:
          'A structured journey from beginner to confident in $topic.',
      units: units,
    );
  }
}
