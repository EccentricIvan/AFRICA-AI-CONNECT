import 'package:drift/drift.dart';
import 'students_table.dart';

/// Per-topic progress level for a student. One row per student+topic pair.
class TopicProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get topic => text()();
  // 0–100 mastery score, updated after each session
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sessionsCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {studentId, topic},
      ];
}
