import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/users_table.dart';
import 'tables/marketplace_listings_table.dart';
import 'daos/user_dao.dart';
import 'daos/marketplace_dao.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Users, MarketplaceListings], daos: [UserDao, MarketplaceDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(marketplaceListings);
          if (from < 3) await m.addColumn(marketplaceListings, marketplaceListings.imagePath);
          if (from < 4) await m.addColumn(users, users.firebaseUid);
          if (from < 5) {
            await m.addColumn(users, users.about);
            await m.addColumn(users, users.avatarPath);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'otic_connect');
  }
}
