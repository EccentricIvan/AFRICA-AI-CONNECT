import 'package:drift/drift.dart';

/// Real mentor directory — created directly via "Become a Mentor" (no
/// application/approval gate), same "this device's own content" shape as
/// MarketplaceListings/Jobs. No seeded content.
class Mentors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get expertise => text()();
  TextColumn get location => text()();
  IntColumn get yearsExp => integer()();
  TextColumn get colorKey => text()();
  /// What the mentor offers — free-text details/description, filled in on
  /// the "Become a Mentor" form.
  TextColumn get bio => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
