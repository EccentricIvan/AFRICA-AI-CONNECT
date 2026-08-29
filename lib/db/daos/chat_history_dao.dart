import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/chat_history_tables.dart';

part 'chat_history_dao.g.dart';

@DriftAccessor(tables: [ChatSessions, ChatMessages])
class ChatHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ChatHistoryDaoMixin {
  ChatHistoryDao(super.db);

  /// Reactive message stream for one session, oldest first.
  Stream<List<ChatMessage>> watchMessages(int sessionId) {
    return (select(chatMessages)
          ..where((m) => m.sessionId.equals(sessionId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// The session a new message should be appended to: the most recently
  /// created one if any exists, otherwise a freshly created one.
  Future<int> getOrCreateActiveSession() async {
    final existing =
        await (select(chatSessions)
              ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(chatSessions).insert(const ChatSessionsCompanion());
  }

  /// Starts a fresh conversation — used by the chat screen's "New chat".
  Future<int> startNewSession() =>
      into(chatSessions).insert(const ChatSessionsCompanion());

  Future<void> addMessage({
    required int sessionId,
    required bool isUser,
    required String content,
    String? matchedIntentKey,
    String? matchedCategory,
    String? webSourceName,
    String? webSourceUrl,
  }) {
    return into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        sessionId: sessionId,
        isUser: isUser,
        content: content,
        matchedIntentKey: Value(matchedIntentKey),
        matchedCategory: Value(matchedCategory),
        webSourceName: Value(webSourceName),
        webSourceUrl: Value(webSourceUrl),
      ),
    );
  }

  /// The category of the most recent assistant reply in this session — used
  /// as a tie-breaker for the next ambiguous match, never to generate text.
  Future<String?> mostRecentAssistantCategory(int sessionId) async {
    final row =
        await (select(chatMessages)
              ..where(
                (m) => m.sessionId.equals(sessionId) & m.isUser.equals(false),
              )
              ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.matchedCategory;
  }

  /// Deletes messages older than [maxAge], then any session left with no
  /// messages at all — called once at app startup.
  Future<void> pruneOlderThan(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    await (delete(
      chatMessages,
    )..where((m) => m.createdAt.isSmallerThanValue(cutoff))).go();

    final sessions = await select(chatSessions).get();
    for (final session in sessions) {
      final remaining =
          await (select(
            chatMessages,
          )..where((m) => m.sessionId.equals(session.id))).get();
      if (remaining.isEmpty) {
        await (delete(
          chatSessions,
        )..where((s) => s.id.equals(session.id))).go();
      }
    }
  }
}
