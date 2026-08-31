import 'package:drift/drift.dart';

/// A completable unit within a Course (skill). Seeded from
/// assets/skills/skills_content.json — a content pack, not hardcoded Dart
/// — same shape as the offline chat knowledge base's asset-seeded content.
class CourseTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  TextColumn get title => text()();
  /// The actual reading material for this topic. A `resourceType` of
  /// 'pdf' is a placeholder for real PDF attachments later — for now
  /// every topic ships as real curated text.
  TextColumn get resourceText => text().withDefault(const Constant(''))();
  TextColumn get resourceType => text().withDefault(const Constant('text'))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get pointsValue => integer().withDefault(const Constant(10))();
}

/// One row per time the local user opens a topic's reading material — the
/// quiz stays locked until at least one view exists, so points/streak
/// require actually engaging with the resource, not just guessing answers.
class TopicResourceViews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer()();
  DateTimeColumn get viewedAt => dateTime().withDefault(currentDateAndTime)();
}

/// A single multiple-choice question gating a topic's completion.
/// `correctIndex` is 0-3, indexing optionA..optionD.
@DataClassName('QuizQuestionRow')
class TopicQuizQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer()();
  TextColumn get question => text()();
  TextColumn get optionA => text()();
  TextColumn get optionB => text()();
  TextColumn get optionC => text()();
  TextColumn get optionD => text()();
  IntColumn get correctIndex => integer()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

/// One row per completed topic (all quiz questions answered correctly) —
/// absence of a row means not completed. No userId column (device is
/// single-user).
class TopicCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer()();
  DateTimeColumn get completedAt => dateTime().withDefault(currentDateAndTime)();
}
