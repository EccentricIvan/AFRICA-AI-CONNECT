import 'package:drift/drift.dart';

/// One row per chat conversation. A new session starts when the user taps
/// "New chat" or when the previous session has aged past the retention
/// window — see ChatHistoryDao.getOrCreateActiveSession.
class ChatSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per message, user or assistant. Persisted so conversation
/// history survives app restart, and so the most recent matched intent's
/// category can bias the next ambiguous match (see
/// ChatHistoryDao.mostRecentAssistantCategory) — never used to generate
/// text, only to help pick among existing answers.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  BoolColumn get isUser => boolean()();
  TextColumn get content => text()();
  /// Which curated intent (if any) produced this reply — null for user
  /// messages, and for assistant replies that came from the SALT tier, the
  /// web-lookup tier, or the generic fallback rather than a curated intent.
  TextColumn get matchedIntentKey => text().nullable()();
  TextColumn get matchedCategory => text().nullable()();
  /// Set only for a WebLookupService result — the source name/link to
  /// re-render this reply with its distinct "from the web, unverified"
  /// styling after an app restart, not as if it were a normal vetted reply.
  TextColumn get webSourceName => text().nullable()();
  TextColumn get webSourceUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
