import 'package:drift/drift.dart';

/// A chat thread. `type` distinguishes what it's about (a Community group
/// chat, a 1:1 thread with a mentor, or a marketplace buyer/seller chat) and
/// `subjectId` points at the relevant row (groupId/mentorId/listingId) —
/// same no-DB-FK convention as ChatMessages.sessionId, filtered explicitly
/// in DAO queries rather than enforced at the schema level.
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'group' | 'mentor' | 'marketplace'
  IntColumn get subjectId => integer()();
  TextColumn get title => text()();
  TextColumn get counterpartName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastMessageAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per chat message. `senderIsMe` distinguishes the local user's
/// messages from the other party's — there's no second real device yet
/// (see CLAUDE.md), so counterpart messages are seeded/simulated locally
/// under `senderName`, not a real remote user.
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer()();
  BoolColumn get senderIsMe => boolean()();
  TextColumn get senderName => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
