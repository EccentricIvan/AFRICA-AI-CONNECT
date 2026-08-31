import 'package:drift/drift.dart';

/// Single-user-per-device: this table only ever holds one row (id = 1).
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoSyncEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pushNotificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get communityUpdatesEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
