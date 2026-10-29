import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/learning_paths_table.dart';

part 'path_dao.g.dart';

@DriftAccessor(tables: [LearningPaths])
class PathDao extends DatabaseAccessor<OticDatabase> with _$PathDaoMixin {
  PathDao(super.db);

  Future<List<LearningPath>> getPathsForStudent(int studentId) =>
      (select(learningPaths)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.lastAccessedAt)]))
          .get();

  Future<LearningPath?> getPath(int studentId, String topic) =>
      (select(learningPaths)
            ..where((t) =>
                t.studentId.equals(studentId) & t.topic.equals(topic)))
          .getSingleOrNull();

  /// Insert new path or replace if topic already exists for this student.
  Future<void> upsertPath(LearningPathsCompanion path) async {
    await into(learningPaths).insertOnConflictUpdate(path);
  }

  Future<void> markLessonComplete({
    required int pathId,
    required int unitIndex,
    required int lessonIndex,
    required String updatedUnitsJson,
    required int completedLessons,
    required int nextUnit,
    required int nextLesson,
  }) =>
      (update(learningPaths)..where((t) => t.id.equals(pathId))).write(
        LearningPathsCompanion(
          unitsJson: Value(updatedUnitsJson),
          completedLessons: Value(completedLessons),
          currentUnit: Value(nextUnit),
          currentLesson: Value(nextLesson),
          lastAccessedAt: Value(DateTime.now()),
        ),
      );

  Future<void> touch(int pathId) =>
      (update(learningPaths)..where((t) => t.id.equals(pathId))).write(
        LearningPathsCompanion(lastAccessedAt: Value(DateTime.now())),
      );

  Future<void> deletePath(int pathId) =>
      (delete(learningPaths)..where((t) => t.id.equals(pathId))).go();
}
