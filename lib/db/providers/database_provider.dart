import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database.dart';
import '../daos/user_dao.dart';
import '../daos/marketplace_dao.dart';

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
