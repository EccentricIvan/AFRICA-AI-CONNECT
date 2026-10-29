import 'package:drift/drift.dart';
import 'students_table.dart';

/// One AI-generated learning path per student+topic.
/// Units and lessons stored as JSON — no normalisation needed at this scale.
class LearningPaths extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get topic => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  // JSON: [{title, lessons:[{title, isCompleted}]}]
  TextColumn get unitsJson => text().withDefault(const Constant('[]'))();
  IntColumn get totalLessons => integer().withDefault(const Constant(0))();
  IntColumn get completedLessons => integer().withDefault(const Constant(0))();
  // Index of the active unit/lesson
  IntColumn get currentUnit => integer().withDefault(const Constant(0))();
  IntColumn get currentLesson => integer().withDefault(const Constant(0))();
  DateTimeColumn get generatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastAccessedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {studentId, topic},
      ];
}
