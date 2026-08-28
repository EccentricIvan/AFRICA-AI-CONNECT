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
    String? location,
    String? imagePath,
  }) {
    return into(marketplaceListings).insert(
      MarketplaceListingsCompanion.insert(
        title: title,
        price: price,
        category: category,
        sellerName: sellerName,
        location: Value(location),
        imagePath: Value(imagePath),
      ),
    );
  }
}
