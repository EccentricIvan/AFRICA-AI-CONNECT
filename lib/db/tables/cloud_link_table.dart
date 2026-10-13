import 'package:drift/drift.dart';

/// This device's link to its school's cloud (schema 34), one row at most.
/// No row: the cloud is off and nothing leaves the device.
///
/// Holds no secret: the device proves itself by signing each request with
/// its own key (`sync_identity.signing_seed`); the server decides its
/// school and role from that key, set when it enrolled with a one-time
/// code.
@DataClassName('CloudLinkData')
class CloudLink extends Table {
  @override
  String get tableName => 'cloud_link';

  IntColumn get id => integer()();

  /// e.g. `https://cloud.school.ug`, as the Admin typed it.
  TextColumn get baseUrl => text()();
  TextColumn get schoolName => text()();

  /// `admin`, `teacher` or `learner`, as the server enrolled it.
  TextColumn get role => text()();

  /// ISO-8601 UTC.
  TextColumn get enrolledAt => text()();

  /// The last send: when, and its error (null when it worked).
  TextColumn get lastSentAt => text().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
