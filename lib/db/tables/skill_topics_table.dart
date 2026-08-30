import 'package:drift/drift.dart';

/// A completable unit within a Course (skill). Seeded/curated, same shape
/// as Courses itself.
class CourseTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  TextColumn get title => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get pointsValue => integer().withDefault(const Constant(10))();
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
