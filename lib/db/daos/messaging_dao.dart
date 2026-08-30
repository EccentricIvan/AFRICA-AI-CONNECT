import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/messaging_tables.dart';

part 'messaging_dao.g.dart';

@DriftAccessor(tables: [Conversations, Messages])
class MessagingDao extends DatabaseAccessor<AppDatabase>
    with _$MessagingDaoMixin {
  MessagingDao(super.db);

  /// Reactive conversation list, most recently active first.
  Stream<List<Conversation>> watchConversations() {
    return (select(conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastMessageAt)]))
        .watch();
  }

  Stream<Conversation?> watchConversation(int id) =>
      (select(conversations)..where((c) => c.id.equals(id)))
          .watchSingleOrNull();

  /// Reactive message stream for one conversation, oldest first.
  Stream<List<Message>> watchMessages(int conversationId) {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .watch();
  }

  /// Idempotent — reuses the existing thread for the same type+subject
  /// instead of creating a duplicate every time "Connect"/"Chat" is tapped
  /// again.
  Future<int> getOrCreateConversation({
    required String type,
    required int subjectId,
    required String title,
    String? counterpartName,
  }) async {
    final existing = await (select(conversations)
          ..where((c) => c.type.equals(type) & c.subjectId.equals(subjectId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(conversations).insert(
      ConversationsCompanion.insert(
        type: type,
        subjectId: subjectId,
        title: title,
        counterpartName: Value(counterpartName),
      ),
    );
  }

  Future<void> sendMessage({
    required int conversationId,
    required bool senderIsMe,
    required String senderName,
    required String body,
  }) async {
    final now = DateTime.now();
    await into(messages).insert(
      MessagesCompanion.insert(
        conversationId: conversationId,
        senderIsMe: senderIsMe,
        senderName: senderName,
        body: body,
        createdAt: Value(now),
      ),
    );
    await (update(
      conversations,
    )..where((c) => c.id.equals(conversationId))).write(
      ConversationsCompanion(lastMessageAt: Value(now)),
    );
  }
}
