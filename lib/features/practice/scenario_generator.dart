import 'dart:convert';
import '../../ai_core/inference/inference_engine.dart';
import 'scenario_models.dart';

class ScenarioGenerator {
  ScenarioGenerator({required this._engine});

  final InferenceEngine _engine;

  Future<Scenario> generate({required String topic}) async {
    final prompt = '''You are a practical skills teacher. Create a real-world scenario as valid JSON.

Topic: $topic

Respond ONLY with this JSON (no explanation, no markdown):
{
  "situation": "A 2-3 sentence description of a real-world situation involving $topic.",
  "challenge": "One clear question: what would you do or decide in this situation?"
}

Rules:
- Situation must be realistic and relatable
- Challenge must be open-ended (no single correct answer)
- Keep language simple and clear
- No markdown, ONLY raw JSON''';

    try {
      final raw = await _engine.generate(
        prompt: prompt,
        maxTokens: 300,
        temperature: 0.8,
      );
      return _parse(topic, raw);
    } catch (_) {
      return _fallback(topic);
    }
  }

  Future<String> evaluate({
    required String topic,
    required String situation,
    required String challenge,
    required String studentResponse,
  }) async {
    final prompt = '''You are a supportive teacher evaluating a student's response.

Topic: $topic
Situation: $situation
Challenge: $challenge
Student's response: $studentResponse

Give encouraging, constructive feedback in 2-3 sentences:
1. What the student got right
2. What they could strengthen or consider
3. A follow-up question to deepen their thinking

Keep it warm and practical. Do not give the "correct" answer — guide the student to think further.
Feedback:''';

    try {
      return await _engine.generate(
        prompt: prompt,
        maxTokens: 250,
        temperature: 0.7,
      );
    } catch (_) {
      return 'Great effort! You engaged with the scenario thoughtfully. '
          'Think about what resources or people you might involve, '
          'and what the longer-term impact of your decision could be.';
    }
  }

  Scenario _parse(String topic, String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1) throw const FormatException('No JSON');

    final data = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    return Scenario(
      topic: topic,
      situation: data['situation'] as String? ?? 'A situation involving $topic.',
      challenge: data['challenge'] as String? ?? 'What would you do?',
    );
  }

  Scenario _fallback(String topic) => Scenario(
        topic: topic,
        situation:
            'You are working on a project that requires applying your knowledge of $topic. '
            'Your team is relying on you to make an important decision, '
            'and you have limited time to figure out the right approach.',
        challenge:
            'What steps would you take to solve the problem, '
            'and how would you use your understanding of $topic to guide your decision?',
      );
}
