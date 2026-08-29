import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/db/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatHistoryDao', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('getOrCreateActiveSession creates then reuses a session', () async {
      final first = await db.chatHistoryDao.getOrCreateActiveSession();
      final second = await db.chatHistoryDao.getOrCreateActiveSession();
      expect(second, first);
    });

    test('startNewSession always creates a fresh session', () async {
      final first = await db.chatHistoryDao.startNewSession();
      final second = await db.chatHistoryDao.startNewSession();
      expect(second, isNot(first));
    });

    test('mostRecentAssistantCategory reads the last assistant reply only', () async {
      final sessionId = await db.chatHistoryDao.getOrCreateActiveSession();
      await db.chatHistoryDao.addMessage(
        sessionId: sessionId,
        isUser: true,
        content: 'how do I save money?',
      );
      await db.chatHistoryDao.addMessage(
        sessionId: sessionId,
        isUser: false,
        content: 'answer',
        matchedIntentKey: 'budget_and_save',
        matchedCategory: 'finance',
      );
      await db.chatHistoryDao.addMessage(
        sessionId: sessionId,
        isUser: true,
        content: 'what about for farmers?',
      );

      final category = await db.chatHistoryDao.mostRecentAssistantCategory(
        sessionId,
      );
      expect(category, 'finance');
    });

    test('pruneOlderThan removes only messages past the cutoff', () async {
      final sessionId = await db.chatHistoryDao.getOrCreateActiveSession();
      final old = DateTime.now().subtract(const Duration(days: 40));
      final recent = DateTime.now().subtract(const Duration(days: 1));

      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion.insert(
          sessionId: sessionId,
          isUser: true,
          content: 'old message',
          createdAt: Value(old),
        ),
      );
      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion.insert(
          sessionId: sessionId,
          isUser: true,
          content: 'recent message',
          createdAt: Value(recent),
        ),
      );

      await db.chatHistoryDao.pruneOlderThan(const Duration(days: 30));

      final remaining = await db.chatHistoryDao.watchMessages(sessionId).first;
      expect(remaining, hasLength(1));
      expect(remaining.single.content, 'recent message');
    });

    test('pruneOlderThan removes a session left with no messages', () async {
      final sessionId = await db.chatHistoryDao.getOrCreateActiveSession();
      await db.into(db.chatMessages).insert(
        ChatMessagesCompanion.insert(
          sessionId: sessionId,
          isUser: true,
          content: 'ancient message',
          createdAt: Value(DateTime.now().subtract(const Duration(days: 90))),
        ),
      );

      await db.chatHistoryDao.pruneOlderThan(const Duration(days: 30));

      final sessions = await db.select(db.chatSessions).get();
      expect(sessions, isEmpty);
    });
  });
}
