import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/users_table.dart';
import 'tables/marketplace_listings_table.dart';
import 'tables/chat_content_tables.dart';
import 'tables/chat_history_tables.dart';
import 'tables/messaging_tables.dart';
import 'tables/settings_table.dart';
import 'tables/jobs_table.dart';
import 'tables/courses_table.dart';
import 'tables/mentors_table.dart';
import 'tables/groups_table.dart';
import 'daos/user_dao.dart';
import 'daos/marketplace_dao.dart';
import 'daos/chat_content_dao.dart';
import 'daos/chat_history_dao.dart';
import 'daos/messaging_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/jobs_dao.dart';
import 'daos/courses_dao.dart';
import 'daos/mentors_dao.dart';
import 'daos/groups_dao.dart';
import 'chat_content_seed.dart';
import 'jobs_seed.dart';
import 'courses_seed.dart';
import 'mentors_seed.dart';

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
    Conversations,
    Messages,
    Settings,
    Jobs,
    JobApplications,
    Courses,
    CourseProgress,
    Mentors,
    MentorApplications,
    Groups,
    GroupMembers,
  ],
  daos: [
    UserDao,
    MarketplaceDao,
    ChatContentDao,
    ChatHistoryDao,
    MessagingDao,
    SettingsDao,
    JobsDao,
    CoursesDao,
    MentorsDao,
    GroupsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only: an in-memory database with a real, freshly-run migration
  /// (including seeding), instead of the on-disk file _openConnection uses.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedChatContentFromAsset(chatContentDao);
          await settingsDao.ensureRowExists();
          await seedJobsIfEmpty(jobsDao);
          await seedCoursesIfEmpty(coursesDao);
          await seedMentorsIfEmpty(mentorsDao);
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
          if (from < 8) {
            await m.createTable(conversations);
            await m.createTable(messages);
            await m.createTable(settings);
            await settingsDao.ensureRowExists();
          }
          if (from < 9) {
            await m.addColumn(users, users.resumeText);
            await m.createTable(jobs);
            await m.createTable(jobApplications);
            await seedJobsIfEmpty(jobsDao);
          }
          if (from < 10) {
            await m.createTable(courses);
            await m.createTable(courseProgress);
            await seedCoursesIfEmpty(coursesDao);
          }
          if (from < 11) {
            await m.createTable(mentors);
            await m.createTable(mentorApplications);
            await m.createTable(groups);
            await m.createTable(groupMembers);
            await seedMentorsIfEmpty(mentorsDao);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'otic_connect');
  }

  /// Deletes every row of personal/user-generated data — called on sign-out
  /// so a shared device doesn't carry the previous person's data into the
  /// next session (see the "Sign out" tile in Settings). Deliberately
  /// leaves the offline chat knowledge base (ChatIntents/Patterns/
  /// ResponseVariants/ContentMeta) untouched — that's shared reference
  /// content, not personal data, and gets re-seeded from the bundled asset
  /// on next launch regardless.
  ///
  /// Extend this list whenever a new table of personal/user-generated data
  /// is added.
  Future<void> clearAllLocalData() async {
    await transaction(() async {
      await delete(messages).go();
      await delete(conversations).go();
      await delete(chatMessages).go();
      await delete(chatSessions).go();
      await delete(marketplaceListings).go();
      await delete(jobApplications).go();
      await delete(courseProgress).go();
      await delete(mentorApplications).go();
      await delete(groupMembers).go();
      await delete(groups).go();
      await delete(settings).go();
      await delete(users).go();
    });
  }
}
