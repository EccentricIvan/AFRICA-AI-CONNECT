import 'package:drift/drift.dart';

/// Curated skills-training programmes — seeded content (see
/// courses_seed.dart), same "team-curated, not user-generated" shape as
/// Jobs.
class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  TextColumn get iconKey => text()();
  TextColumn get colorKey => text()();
  IntColumn get lessonCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per course the local user has started — absence of a row means
/// not started. No userId column needed (device is single-user).
///
/// Explicit @DataClassName — "CourseProgress" doesn't singularize cleanly
/// under drift's default trailing-"s" stripping.
@DataClassName('CourseProgressRow')
class CourseProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer()();
  RealColumn get progressPercent =>
      real().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('in_progress'))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
