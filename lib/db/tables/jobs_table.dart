import 'package:drift/drift.dart';

/// Real user-posted job listings — posted via the "Post a Job" form, same
/// "this device's own content" shape as MarketplaceListings. No seeded
/// content: an empty table until someone actually posts something.
class Jobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get employer => text()();
  TextColumn get location => text().nullable()();
  TextColumn get type => text()(); // 'Full-time' | 'Part-time' | 'Contract'
  TextColumn get description => text().nullable()();
  TextColumn get requirements => text().nullable()();
  TextColumn get education => text().nullable()();
  /// Optional "nice to have" / good-to-have skills — distinct from
  /// required qualifications.
  TextColumn get niceToHave => text().nullable()();
  /// Category key mapped to an AppColors constant in the UI layer — see
  /// MarketplaceListings.category for the same convention. Derived from
  /// `type` at posting time, not a separate user choice.
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
