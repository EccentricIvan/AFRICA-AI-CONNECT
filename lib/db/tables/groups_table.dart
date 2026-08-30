import 'package:drift/drift.dart';

/// A community group. `mentorId` is set only for a mentor's auto-created
/// circle (see GroupsDao.getOrCreateMentorGroup) — null for a group a user
/// created directly from Community.
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get location => text().nullable()();
  TextColumn get iconKey => text()();
  TextColumn get colorKey => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get mentorId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per member. `isMe` marks the local user's own membership — the
/// only membership this device can actually toggle (see CLAUDE.md: no
/// second real device yet).
class GroupMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer()();
  TextColumn get memberName => text()();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}
