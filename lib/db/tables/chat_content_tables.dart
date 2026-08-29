import 'package:drift/drift.dart';

/// One row per curated intent (a topic the offline chat can answer about),
/// independent of language — see [ChatPatterns]/[ChatResponseVariants] for
/// the per-locale content. Seeded from assets/offline/offline_chat.json on
/// first run, then grown over time by ChatContentSyncService.
class ChatIntents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable key (e.g. 'business_start') — how patterns/variants reference
  /// this intent, and how content-pack updates match against existing rows.
  TextColumn get intentKey => text().unique()();
  TextColumn get category => text()();
  TextColumn get sourceTitle => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
}

/// One row per trigger phrase, per locale, per intent — what
/// OfflineChatService scores the user's message against to find the
/// best-matching intent. A genuine multi-row table like
/// MarketplaceListings, not a Users-style singleton.
class ChatPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get intentKey => text()();
  TextColumn get locale => text()();
  TextColumn get pattern => text()();
}

/// One row per possible reply phrasing, per locale, per intent. Multiple
/// variants let the same intent answer differently over repeated asks
/// instead of always returning one hardcoded string — see
/// ChatContentDao.pickVariant for the least-recently-used rotation.
class ChatResponseVariants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get intentKey => text()();
  TextColumn get locale => text()();
  TextColumn get variantText => text()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
}

/// Singleton row (like Users) tracking which content-pack version has been
/// applied locally, so ChatContentSyncService only merges genuinely newer
/// content instead of re-fetching/re-inserting on every app launch.
class ChatContentMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get appliedContentVersion =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
