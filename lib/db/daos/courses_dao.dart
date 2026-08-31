import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/courses_table.dart';
import '../tables/skill_topics_table.dart';

part 'courses_dao.g.dart';

@DriftAccessor(
  tables: [
    Courses,
    CourseProgress,
    CourseTopics,
    TopicQuizQuestions,
    TopicCompletions,
    TopicResourceViews,
  ],
)
class CoursesDao extends DatabaseAccessor<AppDatabase>
    with _$CoursesDaoMixin {
  CoursesDao(super.db);

  Stream<List<Course>> watchCourses() {
    return (select(courses)..orderBy([(c) => OrderingTerm.asc(c.id)])).watch();
  }

  Stream<Course?> watchCourse(int id) =>
      (select(courses)..where((c) => c.id.equals(id))).watchSingleOrNull();

  /// Every course's progress row at once — used to group courses into
  /// Continue/Recommended/Journey sections without one stream per course.
  Stream<List<CourseProgressRow>> watchAllProgress() {
    return select(courseProgress).watch();
  }

  /// Reactive — null means not started.
  Stream<CourseProgressRow?> watchProgress(int courseId) {
    return (select(courseProgress)
          ..where((p) => p.courseId.equals(courseId))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<int> seedCourse({
    required String title,
    required String subtitle,
    required String iconKey,
    required String colorKey,
    required int lessonCount,
  }) {
    return into(courses).insert(
      CoursesCompanion.insert(
        title: title,
        subtitle: subtitle,
        iconKey: iconKey,
        colorKey: colorKey,
        lessonCount: Value(lessonCount),
      ),
    );
  }

  Future<bool> hasAnyCourses() async =>
      (await (select(courses)..limit(1)).get()).isNotEmpty;

  /// Recomputes a course's progress row from its real topic completions —
  /// called after every completeTopic. progressPercent is the real
  /// completed/total ratio; status is 'not_started'/'in_progress'/
  /// 'completed' accordingly.
  Future<void> recomputeCourseProgress(int courseId) async {
    final topics = await (select(
      courseTopics,
    )..where((t) => t.courseId.equals(courseId))).get();
    if (topics.isEmpty) return;

    final topicIds = topics.map((t) => t.id).toList();
    final completions = await (select(
      topicCompletions,
    )..where((c) => c.topicId.isIn(topicIds))).get();
    final completedCount = completions.length;
    final total = topics.length;
    final percent = completedCount / total;
    final status = completedCount == 0
        ? 'not_started'
        : completedCount == total
            ? 'completed'
            : 'in_progress';

    final existing = await (select(courseProgress)
          ..where((p) => p.courseId.equals(courseId))
          ..limit(1))
        .getSingleOrNull();

    if (status == 'not_started') {
      if (existing != null) {
        await (delete(
          courseProgress,
        )..where((p) => p.id.equals(existing.id))).go();
      }
      return;
    }

    if (existing == null) {
      await into(courseProgress).insert(
        CourseProgressCompanion.insert(
          courseId: courseId,
          progressPercent: Value(percent),
          status: Value(status),
          completedAt: status == 'completed' ? Value(DateTime.now()) : const Value.absent(),
        ),
      );
      return;
    }

    await (update(courseProgress)..where((p) => p.id.equals(existing.id)))
        .write(
      CourseProgressCompanion(
        progressPercent: Value(percent),
        status: Value(status),
        completedAt: status == 'completed' ? Value(DateTime.now()) : const Value(null),
      ),
    );
  }

  /// Count of courses with status 'completed' — feeds Profile/Home stats.
  Future<int> completedCount() async {
    final rows = await (select(
      courseProgress,
    )..where((p) => p.status.equals('completed'))).get();
    return rows.length;
  }

  // ── Topics / quizzes ──

  Stream<List<CourseTopic>> watchTopics(int courseId) {
    return (select(courseTopics)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .watch();
  }

  Stream<List<QuizQuestionRow>> watchQuizQuestions(int topicId) {
    return (select(topicQuizQuestions)
          ..where((q) => q.topicId.equals(topicId))
          ..orderBy([(q) => OrderingTerm.asc(q.orderIndex)]))
        .watch();
  }

  /// Reactive — true once this topic has been completed.
  Stream<bool> watchTopicCompleted(int topicId) {
    return (select(topicCompletions)
          ..where((c) => c.topicId.equals(topicId)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  /// Reactive — true once the local user has opened this topic's reading
  /// material at least once. The quiz stays locked until this is true.
  Stream<bool> watchResourceViewed(int topicId) {
    return (select(topicResourceViews)
          ..where((v) => v.topicId.equals(topicId)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  Future<void> markResourceViewed(int topicId) async {
    final existing = await (select(
      topicResourceViews,
    )..where((v) => v.topicId.equals(topicId))).getSingleOrNull();
    if (existing != null) return;
    await into(
      topicResourceViews,
    ).insert(TopicResourceViewsCompanion.insert(topicId: topicId));
  }

  /// Idempotent — records completion once; a later re-completion attempt
  /// (e.g. retaking a quiz) is a no-op here, points/streak aren't
  /// re-awarded for the same topic. Requires the resource to have been
  /// viewed first — returns false without recording anything otherwise.
  Future<bool> completeTopic(int topicId) async {
    final viewed = await (select(
      topicResourceViews,
    )..where((v) => v.topicId.equals(topicId))).getSingleOrNull();
    if (viewed == null) return false;

    final existing = await (select(
      topicCompletions,
    )..where((c) => c.topicId.equals(topicId))).getSingleOrNull();
    if (existing != null) return false;
    await into(
      topicCompletions,
    ).insert(TopicCompletionsCompanion.insert(topicId: topicId));
    return true;
  }

  /// Total topics completed across every course — feeds Profile's real
  /// achievements.
  Stream<int> watchCompletedTopicsCount() {
    return select(topicCompletions).watch().map((rows) => rows.length);
  }

  Future<int> seedTopic({
    required int courseId,
    required String title,
    required String resourceText,
    required int orderIndex,
    int pointsValue = 10,
    String resourceType = 'text',
  }) {
    return into(courseTopics).insert(
      CourseTopicsCompanion.insert(
        courseId: courseId,
        title: title,
        resourceText: Value(resourceText),
        resourceType: Value(resourceType),
        orderIndex: Value(orderIndex),
        pointsValue: Value(pointsValue),
      ),
    );
  }

  Future<void> seedQuestion({
    required int topicId,
    required String question,
    required List<String> options,
    required int correctIndex,
    required int orderIndex,
  }) {
    assert(options.length == 4);
    return into(topicQuizQuestions).insert(
      TopicQuizQuestionsCompanion.insert(
        topicId: topicId,
        question: question,
        optionA: options[0],
        optionB: options[1],
        optionC: options[2],
        optionD: options[3],
        correctIndex: correctIndex,
        orderIndex: Value(orderIndex),
      ),
    );
  }
}
