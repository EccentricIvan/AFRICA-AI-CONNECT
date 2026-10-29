import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/session_summaries_table.dart';
import '../tables/topic_progress_table.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [SessionSummaries, TopicProgress])
class SessionDao extends DatabaseAccessor<OticDatabase>
    with _$SessionDaoMixin {
  SessionDao(super.db);

  /// Save a compressed session summary and update topic progress.
  Future<void> saveSession({
    required int studentId,
    required String topic,
    required String summary,
    required String highestStage,
    required int messageCount,
    List<String> strengths = const [],
    List<String> weaknesses = const [],
  }) async {
    await transaction(() async {
      // Insert summary
      await into(sessionSummaries).insert(SessionSummariesCompanion.insert(
        studentId: studentId,
        topic: topic,
        summary: summary,
        highestStage: Value(highestStage),
        messageCount: Value(messageCount),
        strengthsJson: Value(_toJson(strengths)),
        weaknessesJson: Value(_toJson(weaknesses)),
        sessionAt: Value(DateTime.now()),
      ));

      // Upsert topic progress — increment sessions, nudge level
      final existing = await (select(topicProgress)
            ..where((t) =>
                t.studentId.equals(studentId) & t.topic.equals(topic)))
          .getSingleOrNull();

      if (existing == null) {
        await into(topicProgress).insert(TopicProgressCompanion.insert(
          studentId: studentId,
          topic: topic,
          level: Value(_levelForStage(highestStage)),
          sessionsCount: const Value(1),
          lastStudiedAt: Value(DateTime.now()),
        ));
      } else {
        final newLevel = (existing.level +
                _levelForStage(highestStage))
            .clamp(0, 100);
        await (update(topicProgress)
              ..where((t) =>
                  t.studentId.equals(studentId) & t.topic.equals(topic)))
            .write(TopicProgressCompanion(
          level: Value(newLevel),
          sessionsCount: Value(existing.sessionsCount + 1),
          lastStudiedAt: Value(DateTime.now()),
        ));
      }
    });
  }

  Future<List<SessionSummary>> getRecentSessions(int studentId,
          {int limit = 5}) =>
      (select(sessionSummaries)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.sessionAt)])
            ..limit(limit))
          .get();

  Future<List<TopicProgressData>> getTopicProgress(int studentId) =>
      (select(topicProgress)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.level)]))
          .get();

  int _levelForStage(String stage) {
    switch (stage) {
      case 'reflect': return 20;
      case 'create':  return 16;
      case 'apply':   return 12;
      case 'practice':return 8;
      case 'clarify': return 4;
      default:        return 2;
    }
  }

  String _toJson(List<String> list) =>
      '[${list.map((s) => '"$s"').join(',')}]';
}
