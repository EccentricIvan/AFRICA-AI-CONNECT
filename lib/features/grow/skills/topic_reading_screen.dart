import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import 'topic_quiz_screen.dart';

/// The real reading material for a topic — opening this screen marks the
/// resource as viewed, which is what unlocks the quiz (see
/// CoursesDao.completeTopic). Points/streak only ever come from actually
/// completing the quiz, not just opening this screen, but the quiz itself
/// stays locked until the material has been opened at least once.
class TopicReadingScreen extends ConsumerStatefulWidget {
  const TopicReadingScreen({
    super.key,
    required this.topic,
    required this.courseId,
    required this.color,
  });

  final CourseTopic topic;
  final int courseId;
  final Color color;

  @override
  ConsumerState<TopicReadingScreen> createState() => _TopicReadingScreenState();
}

class _TopicReadingScreenState extends ConsumerState<TopicReadingScreen> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget — marking this viewed doesn't need to block render.
    ref.read(coursesDaoProvider).markResourceViewed(widget.topic.id);
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(topicCompletedProvider(widget.topic.id)).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.resourceText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 28),
                if (completed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text(S.literal('Topic completed — you earned points for this.'))),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TopicQuizScreen(
                            topicId: widget.topic.id,
                            courseId: widget.courseId,
                            pointsValue: widget.topic.pointsValue,
                            color: widget.color,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.quiz_outlined),
                      style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                      label: Text(S.literal('Take the Quiz')),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
