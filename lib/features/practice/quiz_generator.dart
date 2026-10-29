import 'dart:convert';
import '../../ai_core/inference/inference_engine.dart';
import '../../curriculum/curriculum_models.dart';

/// Generates a single multiple-choice question calibrated to the student's
/// current mastery level for a topic — used to supplement the static
/// curriculum quiz bank with adaptive difficulty.
class QuizGenerator {
  QuizGenerator({required this._engine});

  final InferenceEngine _engine;

  Future<QuizQuestion?> generate({
    required String topic,
    int masteryLevel = 0,
  }) async {
    final difficulty = masteryLevel < 20
        ? 'beginner'
        : masteryLevel < 50
            ? 'intermediate'
            : 'advanced';

    final prompt = '''You are an expert teacher. Create one multiple-choice quiz question as valid JSON.

Topic: $topic
Difficulty: $difficulty

Respond ONLY with this JSON (no explanation, no markdown):
{
  "question": "The question text here?",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "correctIndex": 0,
  "explanation": "One sentence explaining why this answer is correct."
}

Rules:
- correctIndex is 0-3 (which option is correct)
- Keep the question clear and relevant to $topic
- Make wrong options plausible but clearly distinguishable
- No markdown, ONLY raw JSON''';

    try {
      final raw = await _engine.generate(
        prompt: prompt,
        maxTokens: 350,
        temperature: 0.5,
      );
      return _parse(raw);
    } catch (_) {
      // A malformed/failed generation just means one fewer bonus question —
      // never let this break the (reliable, static) practice quiz flow.
      return null;
    }
  }

  QuizQuestion? _parse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1) return null;

    try {
      final data = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final options = (data['options'] as List<dynamic>? ?? [])
          .map((o) => o.toString())
          .toList();
      final question = data['question'] as String?;
      if (options.length != 4 || question == null || question.isEmpty) {
        return null;
      }

      return QuizQuestion(
        question: question,
        options: options,
        correct: (data['correctIndex'] as num? ?? 0).toInt().clamp(0, 3),
        explanation: data['explanation'] as String? ?? 'This is the correct answer.',
      );
    } catch (_) {
      return null;
    }
  }
}
