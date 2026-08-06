import 'package:drift/drift.dart';

/// Single-user-per-device: this table only ever holds one row (id = 1).
class Users extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get name => text()();
  TextColumn get role => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get firebaseUid => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
