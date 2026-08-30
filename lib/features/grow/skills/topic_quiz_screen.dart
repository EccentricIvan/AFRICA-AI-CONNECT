import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';

/// A short multiple-choice quiz gating a topic's completion. Getting every
/// question right marks the topic complete, awards its points, and records
/// today's activity (feeding the streak) — see database_provider's
/// coursesDao/userStatsDao.
class TopicQuizScreen extends ConsumerStatefulWidget {
  const TopicQuizScreen({
    super.key,
    required this.topicId,
    required this.courseId,
    required this.pointsValue,
    required this.color,
  });

  final int topicId;
  final int courseId;
  final int pointsValue;
  final Color color;

  @override
  ConsumerState<TopicQuizScreen> createState() => _TopicQuizScreenState();
}

class _TopicQuizScreenState extends ConsumerState<TopicQuizScreen> {
  final Map<int, int> _selected = {}; // questionId -> chosen option index
  bool _submitting = false;
  bool _showResults = false;
  Map<int, bool>? _correctByQuestion;

  Future<void> _submit(List<QuizQuestionRow> questions) async {
    final correctByQuestion = <int, bool>{};
    var allCorrect = true;
    for (final q in questions) {
      final chosen = _selected[q.id];
      final isCorrect = chosen == q.correctIndex;
      correctByQuestion[q.id] = isCorrect;
      if (!isCorrect) allCorrect = false;
    }

    setState(() {
      _showResults = true;
      _correctByQuestion = correctByQuestion;
    });

    if (!allCorrect) return;

    setState(() => _submitting = true);
    final newlyCompleted = await ref.read(coursesDaoProvider).completeTopic(widget.topicId);
    if (newlyCompleted) {
      await ref.read(coursesDaoProvider).recomputeCourseProgress(widget.courseId);
      await ref.read(userStatsDaoProvider).awardPoints(widget.pointsValue);
      await ref.read(userStatsDaoProvider).recordActivityToday();
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(quizQuestionsProvider(widget.topicId));
    final completed = ref.watch(topicCompletedProvider(widget.topicId)).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(S.literal('Quiz'))),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load this quiz.'))),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text(S.literal('No quiz questions for this topic yet.')));
          }

          if (completed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 56),
                    const SizedBox(height: 12),
                    Text(
                      S.literal('Topic completed!'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                      child: Text(S.literal('Back to topics')),
                    ),
                  ],
                ),
              ),
            );
          }

          final allAnswered = questions.every((q) => _selected.containsKey(q.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < questions.length; i++) ...[
                      _QuestionCard(
                        index: i + 1,
                        question: questions[i],
                        selected: _selected[questions[i].id],
                        isCorrect: _correctByQuestion?[questions[i].id],
                        showResult: _showResults,
                        color: widget.color,
                        onSelect: (optionIndex) {
                          setState(() {
                            _selected[questions[i].id] = optionIndex;
                            _showResults = false;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_showResults && _correctByQuestion?.containsValue(false) == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          S.literal('Some answers were incorrect — review and try again.'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: !allAnswered || _submitting ? null : () => _submit(questions),
                        style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(S.literal('Submit Quiz')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.isCorrect,
    required this.showResult,
    required this.color,
    required this.onSelect,
  });

  final int index;
  final QuizQuestionRow question;
  final int? selected;
  final bool? isCorrect;
  final bool showResult;
  final Color color;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [question.optionA, question.optionB, question.optionC, question.optionD];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$index. ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < options.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: selected,
                onChanged: (v) => onSelect(v!),
                activeColor: color,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(options[i]),
                tileColor: showResult && selected == i
                    ? (isCorrect == true ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1))
                    : null,
              ),
            if (showResult && isCorrect == false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  S.literal('Not quite — try again.'),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
