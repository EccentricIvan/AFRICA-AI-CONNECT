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

  /// Reactive — true once a conversation exists for this type+subject, e.g.
  /// to show "Connected" instead of "Connect" on a mentor card.
  Stream<bool> watchConversationExists({
    required String type,
    required int subjectId,
  }) {
    return (select(conversations)
          ..where((c) => c.type.equals(type) & c.subjectId.equals(subjectId))
          ..limit(1))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

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

  /// Keeps the local user's identity in step with a profile name change:
  /// their own sent messages, and every place they appear as the
  /// "counterpart" of a thread they themselves are the subject of (a
  /// mentor conversation about them, or a marketplace chat about their own
  /// listing — see CLAUDE.md: no cross-device sync yet, so both cases are
  /// always the local user).
  Future<void> renameMyIdentity(String newName) async {
    await (update(
      conversations,
    )..where((c) => c.type.equals('mentor'))).write(
      ConversationsCompanion(title: Value(newName), counterpartName: Value(newName)),
    );
    await (update(
      conversations,
    )..where((c) => c.type.equals('marketplace'))).write(
      ConversationsCompanion(counterpartName: Value(newName)),
    );
    await (update(messages)..where((m) => m.senderIsMe.equals(true)))
        .write(MessagesCompanion(senderName: Value(newName)));
  }
}
