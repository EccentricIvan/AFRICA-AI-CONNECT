import 'package:drift/drift.dart';

import 'students_table.dart';

/// A learner's work on one assignment, from when it began until it is
/// handed in (then the row goes).
///
/// - Timed assessment (schema 32): when they started it and what they have
///   typed so far, so leaving the screen or closing the app neither
///   restarts the clock nor loses the work. When time runs out, the draft
///   is submitted as it stands.
/// - Untimed assignment (schema 33): when the learner first saw it on
///   Assignments; [draft] stays empty. It only opens the window for
///   [tutorAt].
@DataClassName('AssignmentAttempt')
class AssignmentAttempts extends Table {
  @override
  String get tableName => 'assignment_attempts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get assignmentId => text()();

  /// ISO-8601 UTC, this device's clock.
  TextColumn get startedAt => text()();
  TextColumn get draft => text().withDefault(const Constant(''))();

  /// ISO-8601 UTC: the tutor's first reply to the learner since this row
  /// was made; null when none (schema 33). Kept here so an attempt handed
  /// in by itself when time ran out, or answered days later, still knows.
  TextColumn get tutorAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {studentId, assignmentId},
  ];
}
