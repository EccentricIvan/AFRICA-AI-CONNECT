import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/users_table.dart';
import 'tables/marketplace_listings_table.dart';
import 'tables/chat_content_tables.dart';
import 'tables/chat_history_tables.dart';
import 'daos/user_dao.dart';
import 'daos/marketplace_dao.dart';
import 'daos/chat_content_dao.dart';
import 'daos/chat_history_dao.dart';
import 'chat_content_seed.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    MarketplaceListings,
    ChatIntents,
    ChatPatterns,
    ChatResponseVariants,
    ChatContentMeta,
    ChatSessions,
    ChatMessages,
  ],
  daos: [UserDao, MarketplaceDao, ChatContentDao, ChatHistoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only: an in-memory database with a real, freshly-run migration
  /// (including seeding), instead of the on-disk file _openConnection uses.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedChatContentFromAsset(chatContentDao);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(marketplaceListings);
          if (from < 3) await m.addColumn(marketplaceListings, marketplaceListings.imagePath);
          if (from < 4) await m.addColumn(users, users.firebaseUid);
          if (from < 5) {
            await m.addColumn(users, users.about);
            await m.addColumn(users, users.avatarPath);
          }
          if (from < 6) {
            await m.createTable(chatIntents);
            await m.createTable(chatPatterns);
            await m.createTable(chatResponseVariants);
            await m.createTable(chatContentMeta);
            await m.createTable(chatSessions);
            await m.createTable(chatMessages);
            await seedChatContentFromAsset(chatContentDao);
          }
          if (from < 7) {
            await m.addColumn(marketplaceListings, marketplaceListings.sellerPhone);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'otic_connect');
  }
}
