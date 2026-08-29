import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database.dart';
import '../daos/user_dao.dart';
import '../daos/marketplace_dao.dart';
import '../daos/chat_content_dao.dart';
import '../daos/chat_history_dao.dart';
import '../chat_content_seed.dart';
import '../../services/offline_chat_service.dart';
import '../../services/chat_content_sync_service.dart';
import '../../services/web_lookup_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final userDaoProvider = Provider<UserDao>((ref) {
  return ref.watch(appDatabaseProvider).userDao;
});

/// Single source of truth for the local user's profile, used by
/// home_screen.dart and profile_screen.dart.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(userDaoProvider).watchUser();
});

// ── Marketplace ──

final marketplaceDaoProvider = Provider<MarketplaceDao>((ref) {
  return ref.watch(appDatabaseProvider).marketplaceDao;
});

/// Which category chip is currently active as a filter. null = "See all".
final selectedMarketplaceCategoryProvider = StateProvider<String?>((ref) => null);

/// Reactive listings, automatically refiltered whenever
/// [selectedMarketplaceCategoryProvider] changes.
final marketplaceListingsProvider = StreamProvider<List<MarketplaceListing>>((ref) {
  final category = ref.watch(selectedMarketplaceCategoryProvider);
  return ref.watch(marketplaceDaoProvider).watchListings(category: category);
});

// ── AI Chat ──

final chatContentDaoProvider = Provider<ChatContentDao>((ref) {
  return ref.watch(appDatabaseProvider).chatContentDao;
});

final chatHistoryDaoProvider = Provider<ChatHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).chatHistoryDao;
});

/// The session the chat screen is currently reading/writing. Starts as the
/// most recently active session (or a fresh one) and is overridden when the
/// user taps "New chat" — see ai_chat_screen.dart.
final activeChatSessionProvider = FutureProvider<int>((ref) {
  return ref.watch(chatHistoryDaoProvider).getOrCreateActiveSession();
});

/// Reactive message history for [activeChatSessionProvider]'s session —
/// emits an empty list (rather than staying in AsyncLoading) until the
/// session id resolves, which is near-instant in practice.
final currentChatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final sessionId = ref.watch(activeChatSessionProvider).valueOrNull;
  if (sessionId == null) return Stream.value(const <ChatMessage>[]);
  return ref.watch(chatHistoryDaoProvider).watchMessages(sessionId);
});

final offlineChatServiceProvider = Provider<OfflineChatService>((ref) {
  return OfflineChatService(ref.watch(chatContentDaoProvider));
});

final chatContentSyncServiceProvider = Provider<ChatContentSyncService>((ref) {
  return ChatContentSyncService(ref.watch(chatContentDaoProvider));
});

final webLookupServiceProvider = Provider<WebLookupService>((ref) {
  return WebLookupService();
});

/// Fire-and-forget startup work for the chat feature. Watched once,
/// non-blockingly, from app.dart — must never delay first paint, so
/// nothing here is awaited before runApp:
/// 1. Re-apply assets/offline/offline_chat.json's curated content. Safe to
///    repeat every launch — upsertIntent replaces patterns wholesale and
///    only appends genuinely new response variants — so bundled content
///    corrections/additions reach existing installs without a schema
///    migration, on the very next launch after an app update.
/// 2. Pull any newer content-pack version from Firestore (silently a no-op
///    if offline — see ChatContentSyncService).
/// 3. Prune conversation history past the retention window.
final chatBootstrapProvider = FutureProvider<void>((ref) async {
  await seedChatContentFromAsset(ref.read(chatContentDaoProvider));
  await ref.read(chatContentSyncServiceProvider).sync();
  await ref.read(chatHistoryDaoProvider).pruneOlderThan(const Duration(days: 30));
});
