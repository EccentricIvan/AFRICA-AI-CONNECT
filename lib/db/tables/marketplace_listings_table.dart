import 'package:drift/drift.dart';

/// One row per product/service listing — a genuine multi-row table,
/// unlike the singleton Users row.
class MarketplaceListings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  /// Stable category key (e.g. 'agriculture'), not the translated label —
  /// see _categoryMeta in marketplace_screen.dart for the key/label map.
  TextColumn get category => text()();
  /// Denormalized snapshot of the seller's name at listing time, not a
  /// foreign key — Users is a fixed singleton row, not a real id space.
  TextColumn get sellerName => text()();
  TextColumn get location => text().nullable()();
  /// Path to a copy of the picked photo in the app's own persistent
  /// documents directory (not the OS picker's temp/cache path, which
  /// isn't guaranteed to survive) — see _savePickedImage in
  /// marketplace_screen.dart.
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
