import 'package:drift/drift.dart';

/// Curated job board postings — seeded content (see jobs_seed.dart), not
/// user-generated, since there's no employer-side "post a job" flow yet.
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get employer => text()();
  TextColumn get location => text().nullable()();
  TextColumn get type => text()(); // 'Full-time' | 'Part-time' | 'Contract'
  TextColumn get description => text().nullable()();
  /// Category key mapped to an AppColors constant in the UI layer — see
  /// MarketplaceListings.category for the same convention.
  TextColumn get colorKey => text()();
  DateTimeColumn get postedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per application. `applicantName` is a denormalized snapshot from
/// Users (the single local user), same convention as
/// MarketplaceListings.sellerName.
class JobApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer()();
  TextColumn get applicantName => text()();
  TextColumn get coverNote => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('submitted'))();
  DateTimeColumn get appliedAt => dateTime().withDefault(currentDateAndTime)();
}
