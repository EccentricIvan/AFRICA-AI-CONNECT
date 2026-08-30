import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import 'skills_screen.dart';
import 'topic_reading_screen.dart';

class CourseTopicsScreen extends ConsumerWidget {
  const CourseTopicsScreen({super.key, required this.courseId});
  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));
    final topicsAsync = ref.watch(topicsProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: Text(S.literal('Skill'))),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load this skill.'))),
        data: (course) {
          if (course == null) {
            return Center(child: Text(S.literal('This skill is no longer available.')));
          }
          final color = colorForCourseKey(course.colorKey);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(iconForCourseKey(course.iconKey), color: color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
                              Text(course.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(S.literal('Topics'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    topicsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => Text(S.literal('Could not load topics.')),
                      data: (topics) {
                        if (topics.isEmpty) {
                          return Text(S.literal('No topics yet for this skill.'));
                        }
                        return Column(
                          children: topics
                              .map((topic) => _TopicRow(topic: topic, color: color))
                              .toList(),
                        );
                      },
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

class _TopicRow extends ConsumerWidget {
  const _TopicRow({required this.topic, required this.color});
  final CourseTopic topic;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(topicCompletedProvider(topic.id)).valueOrNull ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TopicReadingScreen(
              topic: topic,
              courseId: topic.courseId,
              color: color,
            ),
          ),
        ),
        leading: Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : color,
        ),
        title: Text(topic.title),
        subtitle: Text('${topic.pointsValue} ${S.literal('points')}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
