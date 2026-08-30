import 'package:drift/drift.dart';

/// Single-user-per-device: this table only ever holds one row (id = 1).
/// currentStreakDays is recomputed (not just incremented) from
/// ActivityDays every time it changes — see UserStatsDao._recomputeStreak.
class UserStats extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();
  IntColumn get currentStreakDays => integer().withDefault(const Constant(0))();
  IntColumn get bestStreakDays => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per calendar day (id = 'YYYY-MM-DD') with at least one topic
/// completed — presence of a row is what "that day's streak achieved"
/// means. Used to recompute the consecutive-day streak by walking back
/// from today.
class ActivityDays extends Table {
  TextColumn get id => text()();

  @override
  Set<Column> get primaryKey => {id};
}
