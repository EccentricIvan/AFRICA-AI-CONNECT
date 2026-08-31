import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/marketplace_listings_table.dart';

part 'marketplace_dao.g.dart';

@DriftAccessor(tables: [MarketplaceListings])
class MarketplaceDao extends DatabaseAccessor<AppDatabase> with _$MarketplaceDaoMixin {
  MarketplaceDao(super.db);

  /// Reactive listing stream, newest first, optionally filtered to one
  /// category key. `category == null` means no filter — show everything.
  Stream<List<MarketplaceListing>> watchListings({String? category}) {
    final query = select(marketplaceListings)
      ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]);
    if (category != null) {
      query.where((l) => l.category.equals(category));
    }
    return query.watch();
  }

  Future<int> addListing({
    required String title,
    required double price,
    required String category,
    required String sellerName,
    String? sellerPhone,
    String? location,
    String? imagePath,
  }) {
    return into(marketplaceListings).insert(
      MarketplaceListingsCompanion.insert(
        title: title,
        price: price,
        category: category,
        sellerName: sellerName,
        sellerPhone: Value(sellerPhone),
        location: Value(location),
        imagePath: Value(imagePath),
      ),
    );
  }

  /// Every listing on this device was posted by the local user themselves
  /// (no cross-device sync yet — see CLAUDE.md), so a profile name change
  /// updates every listing's seller name rather than picking one out.
  Future<void> renameAllSellers(String newName) {
    return update(
      marketplaceListings,
    ).write(MarketplaceListingsCompanion(sellerName: Value(newName)));
  }

  Future<void> deleteListing(int id) {
    return (delete(marketplaceListings)..where((l) => l.id.equals(id))).go();
  }
}
