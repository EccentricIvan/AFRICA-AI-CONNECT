import 'package:drift/drift.dart';

/// A teacher who signs in on this device with their own PIN.
///
/// Every device can do teacher duties. The Teachers PIN (`TeacherPin`)
/// opens the Teachers area; each teacher then signs in to their profile,
/// and the classes, streams and subjects they create are theirs alone to
/// change (`owner_teacher_id` on those tables). Local only, never synced.
@DataClassName('TeacherProfile')
class TeacherProfiles extends Table {
  @override
  String get tableName => 'teacher_profiles';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// Salted hash of the teacher's PIN, used to check sign-in.
  TextColumn get pinSalt => text()();
  TextColumn get pinHash => text()();

  /// The PIN in the clear, so the Admin can look it up when a teacher
  /// forgets it (Admin → Teachers → Show PIN). Null for teachers added
  /// before this was stored — the Admin resets the PIN to set a fresh one.
  /// These PINs keep learners and staff apart on a shared device; they are
  /// not real security, and the Admin area that reveals them is itself
  /// behind the Admin PIN.
  TextColumn get pinPlain => text().nullable()();

  /// ISO-8601 UTC.
  TextColumn get createdAt => text()();

  /// Portable id, the same on every device the Admin's records reach.
  TextColumn get uuid => text().nullable()();
}
