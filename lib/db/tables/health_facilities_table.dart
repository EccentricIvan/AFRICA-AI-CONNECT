import 'package:drift/drift.dart';

/// Real user-added nearby health facilities — posted via a "Add a nearby
/// service" form, same "this device's own content" shape as
/// MarketplaceListings/Jobs. No seeded content.
class HealthFacilities extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'Clinic' | 'Hospital' | 'Pharmacy' | 'Maternity' | 'Other'
  TextColumn get address => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
