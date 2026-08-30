import 'package:drift/drift.dart';

/// Curated mentor directory — seeded content (see mentors_seed.dart), same
/// "team-curated, not user-generated" shape as Jobs/Courses.
class Mentors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get expertise => text()();
  TextColumn get location => text()();
  IntColumn get yearsExp => integer()();
  TextColumn get colorKey => text()();
  TextColumn get bio => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per "become a mentor" submission. Insert-only for v1 — no
/// reviewer/approval screen yet.
class MentorApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get applicantName => text()();
  TextColumn get expertise => text()();
  TextColumn get message => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get appliedAt => dateTime().withDefault(currentDateAndTime)();
}
