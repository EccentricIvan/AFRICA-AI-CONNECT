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
import 'tables/skill_topics_table.dart';
import 'tables/user_stats_table.dart';
import 'tables/health_facilities_table.dart';
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
import 'daos/user_stats_dao.dart';
import 'daos/health_facilities_dao.dart';
import 'chat_content_seed.dart';
import 'courses_seed.dart';

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
    Groups,
    GroupMembers,
    CourseTopics,
    TopicQuizQuestions,
    TopicCompletions,
    TopicResourceViews,
    UserStats,
    ActivityDays,
    HealthFacilities,
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
    UserStatsDao,
    HealthFacilitiesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only: an in-memory database with a real, freshly-run migration
  /// (including seeding), instead of the on-disk file _openConnection uses.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedChatContentFromAsset(chatContentDao);
          await settingsDao.ensureRowExists();
          await seedCoursesIfEmpty(coursesDao);
          await userStatsDao.ensureRowExists();
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
          }
          if (from < 10) {
            await m.createTable(courses);
            await m.createTable(courseProgress);
          }
          if (from < 11) {
            await m.createTable(mentors);
            await m.createTable(groups);
            await m.createTable(groupMembers);
          }
          if (from < 12) {
            await m.createTable(courseTopics);
            await m.createTable(topicQuizQuestions);
            await m.createTable(topicCompletions);
            await m.createTable(userStats);
            await m.createTable(activityDays);
          }
          if (from < 13) {
            // Real, user-added nearby health facilities — no seed.
            await m.createTable(healthFacilities);

            // Skill topics gained real reading material and a "must read
            // before the quiz unlocks" gate. Wipe and reseed from the
            // content-pack JSON — pre-release, no real course progress
            // exists yet to preserve — rather than leave old rows with a
            // blank resourceText.
            await m.addColumn(courseTopics, courseTopics.resourceText);
            await m.addColumn(courseTopics, courseTopics.resourceType);
            await m.createTable(topicResourceViews);
            await delete(topicCompletions).go();
            await delete(courseProgress).go();
            await delete(topicQuizQuestions).go();
            await delete(courseTopics).go();
            await delete(courses).go();
            await seedCoursesIfEmpty(coursesDao);

            // Jobs and Mentors are no longer curated/seeded content — from
            // this version on they only exist once someone actually posts
            // a job or becomes a mentor through the app. Clear out
            // whatever the old seed left behind so a device that already
            // ran it doesn't keep showing postings nobody created.
            await m.addColumn(jobs, jobs.requirements);
            await m.addColumn(jobs, jobs.education);
            await m.addColumn(jobs, jobs.niceToHave);
            await delete(jobApplications).go();
            await delete(jobs).go();

            final mentorGroups = await (select(
              groups,
            )..where((g) => g.mentorId.isNotNull())).get();
            final mentorGroupIds = mentorGroups.map((g) => g.id).toList();
            if (mentorGroupIds.isNotEmpty) {
              await (delete(
                groupMembers,
              )..where((gm) => gm.groupId.isIn(mentorGroupIds))).go();
              final groupConvos = await (select(conversations)
                    ..where(
                      (c) =>
                          c.type.equals('group') &
                          c.subjectId.isIn(mentorGroupIds),
                    ))
                  .get();
              final groupConvoIds = groupConvos.map((c) => c.id).toList();
              if (groupConvoIds.isNotEmpty) {
                await (delete(
                  messages,
                )..where((msg) => msg.conversationId.isIn(groupConvoIds))).go();
                await (delete(
                  conversations,
                )..where((c) => c.id.isIn(groupConvoIds))).go();
              }
              await (delete(
                groups,
              )..where((g) => g.id.isIn(mentorGroupIds))).go();
            }
            final mentorConvos = await (select(
              conversations,
            )..where((c) => c.type.equals('mentor'))).get();
            final mentorConvoIds = mentorConvos.map((c) => c.id).toList();
            if (mentorConvoIds.isNotEmpty) {
              await (delete(
                messages,
              )..where((msg) => msg.conversationId.isIn(mentorConvoIds))).go();
              await (delete(
                conversations,
              )..where((c) => c.id.isIn(mentorConvoIds))).go();
            }
            await delete(mentors).go();

            // "Apply to Mentor" is gone — becoming a mentor is now
            // immediate, no application/approval step.
            await m.deleteTable('mentor_applications');
          }
          if (from < 14) {
            // Nearby services never needed a phone number — recreate the
            // table without it, preserving name/type/address for any
            // facility already added rather than wiping it.
            await m.alterTable(TableMigration(healthFacilities));
          }
          if (from < 15) {
            // "Delete community" is now a soft close (see GroupsDao.closeGroup)
            // so existing members keep their history and can see why they
            // can no longer post, instead of the group just vanishing.
            await m.addColumn(groups, groups.closedAt);
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
  /// ResponseVariants/ContentMeta) and the Skills content pack
  /// (Courses/CourseTopics/TopicQuizQuestions) untouched — that's shared
  /// reference content, not personal data.
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
      await delete(jobs).go();
      await delete(courseProgress).go();
      await delete(topicCompletions).go();
      await delete(topicResourceViews).go();
      await delete(mentors).go();
      await delete(groupMembers).go();
      await delete(groups).go();
      await delete(healthFacilities).go();
      await delete(settings).go();
      await delete(activityDays).go();
      await delete(userStats).go();
      await delete(users).go();
    });
  }
}
