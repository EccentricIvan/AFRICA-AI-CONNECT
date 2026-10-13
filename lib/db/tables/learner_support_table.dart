import 'package:drift/drift.dart';

/// Extra help a teacher sends one learner: a message, a note to read and a
/// quiz on one topic (schema 33) — on the teacher's device and, after Sync,
/// on that learner's.
///
/// It travels only in the reply to the learner's own progress report, so
/// classmates' devices never receive it (unlike notes, which go to the
/// whole class). Like grades, the teacher owns it: a row changes only with
/// a higher [version]. The learner's device owns [openedAt] and [doneAt],
/// which ride the next report back.
@DataClassName('LearnerSupportItem')
@TableIndex(
  name: 'idx_learner_support_member',
  columns: {#classGroupUuid, #memberKey},
)
class LearnerSupport extends Table {
  @override
  String get tableName => 'learner_support';

  IntColumn get id => integer().autoIncrement()();

  /// Stable id, minted on the teacher's device.
  TextColumn get uuid => text().unique()();
  TextColumn get classGroupUuid => text()();

  /// The learner as their device reports them (`deviceKey/studentId`).
  TextColumn get memberKey => text()();

  /// On the learner's device: `students.id`. Null on the teacher's.
  IntColumn get studentId => integer().nullable()();

  /// Teacher's device: the learner's name and who sent it.
  TextColumn get learnerName => text().withDefault(const Constant(''))();
  IntColumn get teacherId => integer().nullable()();

  TextColumn get subjectId => text()();

  /// A quiz topic of the subject's notes; '' for none.
  TextColumn get topic => text().withDefault(const Constant(''))();

  /// A note of the subject to read; null for none.
  TextColumn get documentTitle => text().nullable()();
  TextColumn get message => text().withDefault(const Constant(''))();

  /// Whether the learner is asked to take the topic's quiz.
  BoolColumn get quiz => boolean().withDefault(const Constant(false))();

  /// Teacher's device: the learner's latest quiz round on the topic when it
  /// was sent, to measure improvement against. Null when they had none.
  IntColumn get baselineCorrect => integer().nullable()();
  IntColumn get baselineTotal => integer().nullable()();

  /// ISO-8601 UTC, the teacher's clock.
  TextColumn get sentAt => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get withdrawn => boolean().withDefault(const Constant(false))();

  /// ISO-8601 UTC, the learner device's clock.
  TextColumn get openedAt => text().nullable()();
  TextColumn get doneAt => text().nullable()();
}
