import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/courses_table.dart';

part 'courses_dao.g.dart';

@DriftAccessor(tables: [Courses, CourseProgress])
class CoursesDao extends DatabaseAccessor<AppDatabase>
    with _$CoursesDaoMixin {
  CoursesDao(super.db);

  Stream<List<Course>> watchCourses() {
    return (select(courses)..orderBy([(c) => OrderingTerm.asc(c.id)])).watch();
  }

  Stream<Course?> watchCourse(int id) =>
      (select(courses)..where((c) => c.id.equals(id))).watchSingleOrNull();

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

  /// Starts the course at 50% if not already started; advances an
  /// in-progress course to 100%/completed. There's no lesson-level content
  /// yet (see CLAUDE.md roadmap), so this two-step progression is the
  /// honest real signal available rather than simulated lesson checkpoints.
  Future<void> advanceProgress(int courseId) async {
    final existing = await (select(courseProgress)
          ..where((p) => p.courseId.equals(courseId))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await into(courseProgress).insert(
        CourseProgressCompanion.insert(
          courseId: courseId,
          progressPercent: const Value(0.5),
          status: const Value('in_progress'),
        ),
      );
      return;
    }

    if (existing.status == 'completed') return;

    await (update(courseProgress)..where((p) => p.id.equals(existing.id)))
        .write(
      CourseProgressCompanion(
        progressPercent: const Value(1.0),
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
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
}
