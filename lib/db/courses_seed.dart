import 'dart:convert';
import 'package:flutter/services.dart';
import 'daos/courses_dao.dart';

/// One-time seed of the curated skills catalog from a content-pack asset
/// (assets/skills/skills_content.json) — categories, topics, their real
/// reading material, and quiz questions. Mirrors exactly how the offline
/// AI chat's knowledge base is seeded from offline_chat.json: the content
/// lives in a data file, not hardcoded Dart, so it can be edited/extended
/// without touching screen code, and could later be refreshed the same
/// way ChatContentSyncService refreshes the chat KB from Firestore.
Future<void> seedCoursesIfEmpty(CoursesDao dao) async {
  if (await dao.hasAnyCourses()) return;

  final raw = await rootBundle.loadString('assets/skills/skills_content.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final courses = decoded['courses'] as List<dynamic>;

  for (final courseJson in courses) {
    final course = courseJson as Map<String, dynamic>;
    final topics = course['topics'] as List<dynamic>;
    final courseId = await dao.seedCourse(
      title: course['title'] as String,
      subtitle: course['subtitle'] as String,
      iconKey: course['iconKey'] as String,
      colorKey: course['colorKey'] as String,
      lessonCount: topics.length,
    );

    for (var t = 0; t < topics.length; t++) {
      final topic = topics[t] as Map<String, dynamic>;
      final questions = topic['questions'] as List<dynamic>;
      final topicId = await dao.seedTopic(
        courseId: courseId,
        title: topic['title'] as String,
        resourceText: topic['resourceText'] as String,
        orderIndex: t,
        pointsValue: (topic['pointsValue'] as num?)?.toInt() ?? 10,
      );

      for (var q = 0; q < questions.length; q++) {
        final question = questions[q] as Map<String, dynamic>;
        final options = (question['options'] as List<dynamic>)
            .map((o) => o as String)
            .toList();
        await dao.seedQuestion(
          topicId: topicId,
          question: question['question'] as String,
          options: options,
          correctIndex: (question['correctIndex'] as num).toInt(),
          orderIndex: q,
        );
      }
    }
  }
}
