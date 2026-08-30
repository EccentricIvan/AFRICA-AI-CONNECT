import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database.dart';
import '../daos/user_dao.dart';
import '../daos/marketplace_dao.dart';
import '../daos/chat_content_dao.dart';
import '../daos/chat_history_dao.dart';
import '../daos/messaging_dao.dart';
import '../daos/settings_dao.dart';
import '../daos/jobs_dao.dart';
import '../daos/courses_dao.dart';
import '../daos/mentors_dao.dart';
import '../daos/groups_dao.dart';
import '../daos/user_stats_dao.dart';
import '../daos/health_facilities_dao.dart';
import '../chat_content_seed.dart';
import '../../services/offline_chat_service.dart';
import '../../services/chat_content_sync_service.dart';
import '../../services/web_lookup_service.dart';

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

// ── Messaging (Mentorship connect / Marketplace seller chat / Community group chat) ──

final messagingDaoProvider = Provider<MessagingDao>((ref) {
  return ref.watch(appDatabaseProvider).messagingDao;
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  return ref.watch(messagingDaoProvider).watchConversations();
});

final conversationProvider = StreamProvider.family<Conversation?, int>((ref, id) {
  return ref.watch(messagingDaoProvider).watchConversation(id);
});

/// Whether a conversation already exists for a given (type, subjectId) pair
/// — e.g. to show "Connected" instead of "Connect" on a mentor card.
final conversationExistsProvider = StreamProvider.family<bool, ({String type, int subjectId})>((ref, params) {
  return ref.watch(messagingDaoProvider).watchConversationExists(
        type: params.type,
        subjectId: params.subjectId,
      );
});

final conversationMessagesProvider = StreamProvider.family<List<Message>, int>((ref, conversationId) {
  return ref.watch(messagingDaoProvider).watchMessages(conversationId);
});

// ── Settings ──

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});

final settingsProvider = StreamProvider<Setting>((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});

/// Fire-and-forget startup work: makes sure the Settings singleton row
/// exists before anything reads it. Watched once, non-blockingly, from
/// app.dart alongside chatBootstrapProvider.
final settingsBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(settingsDaoProvider).ensureRowExists();
});

// ── Jobs ──

final jobsDaoProvider = Provider<JobsDao>((ref) {
  return ref.watch(appDatabaseProvider).jobsDao;
});

final jobsProvider = StreamProvider<List<Job>>((ref) {
  return ref.watch(jobsDaoProvider).watchJobs();
});

final jobProvider = StreamProvider.family<Job?, int>((ref, id) {
  return ref.watch(jobsDaoProvider).watchJob(id);
});

final myJobApplicationProvider = StreamProvider.family<JobApplication?, int>((ref, jobId) {
  return ref.watch(jobsDaoProvider).watchMyApplication(jobId);
});

final myApplicationsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(jobsDaoProvider).watchMyApplicationsCount();
});

// ── Skills / courses ──

final coursesDaoProvider = Provider<CoursesDao>((ref) {
  return ref.watch(appDatabaseProvider).coursesDao;
});

final coursesProvider = StreamProvider<List<Course>>((ref) {
  return ref.watch(coursesDaoProvider).watchCourses();
});

final courseProvider = StreamProvider.family<Course?, int>((ref, id) {
  return ref.watch(coursesDaoProvider).watchCourse(id);
});

final courseProgressProvider = StreamProvider.family<CourseProgressRow?, int>((ref, courseId) {
  return ref.watch(coursesDaoProvider).watchProgress(courseId);
});

final allCourseProgressProvider = StreamProvider<List<CourseProgressRow>>((ref) {
  return ref.watch(coursesDaoProvider).watchAllProgress();
});

final topicsProvider = StreamProvider.family<List<CourseTopic>, int>((ref, courseId) {
  return ref.watch(coursesDaoProvider).watchTopics(courseId);
});

final quizQuestionsProvider = StreamProvider.family<List<QuizQuestionRow>, int>((ref, topicId) {
  return ref.watch(coursesDaoProvider).watchQuizQuestions(topicId);
});

final topicCompletedProvider = StreamProvider.family<bool, int>((ref, topicId) {
  return ref.watch(coursesDaoProvider).watchTopicCompleted(topicId);
});

/// Whether the local user has opened this topic's reading material — the
/// quiz stays locked until this is true.
final resourceViewedProvider = StreamProvider.family<bool, int>((ref, topicId) {
  return ref.watch(coursesDaoProvider).watchResourceViewed(topicId);
});

final completedTopicsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(coursesDaoProvider).watchCompletedTopicsCount();
});

// ── Points / streak ──

final userStatsDaoProvider = Provider<UserStatsDao>((ref) {
  return ref.watch(appDatabaseProvider).userStatsDao;
});

final userStatsProvider = StreamProvider<UserStat>((ref) {
  return ref.watch(userStatsDaoProvider).watchStats();
});

/// Fire-and-forget startup work: makes sure the UserStats singleton row
/// exists before anything reads it, same pattern as settingsBootstrapProvider.
final userStatsBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(userStatsDaoProvider).ensureRowExists();
});

final currentWeekActivityProvider = StreamProvider<List<bool>>((ref) {
  return ref.watch(userStatsDaoProvider).watchCurrentWeekActivity();
});

final hasAnyActivityProvider = StreamProvider<bool>((ref) {
  return ref.watch(userStatsDaoProvider).watchHasAnyActivity();
});

// ── Mentorship ──

final mentorsDaoProvider = Provider<MentorsDao>((ref) {
  return ref.watch(appDatabaseProvider).mentorsDao;
});

final mentorsProvider = StreamProvider<List<Mentor>>((ref) {
  return ref.watch(mentorsDaoProvider).watchMentors();
});

// ── Community groups (also used by Mentorship "Connect") ──

final groupsDaoProvider = Provider<GroupsDao>((ref) {
  return ref.watch(appDatabaseProvider).groupsDao;
});

final groupsProvider = StreamProvider<List<Group>>((ref) {
  return ref.watch(groupsDaoProvider).watchGroups();
});

final myGroupsProvider = StreamProvider<List<Group>>((ref) {
  return ref.watch(groupsDaoProvider).watchMyGroups();
});

final groupProvider = StreamProvider.family<Group?, int>((ref, id) {
  return ref.watch(groupsDaoProvider).watchGroup(id);
});

final groupMembersProvider = StreamProvider.family<List<GroupMember>, int>((ref, groupId) {
  return ref.watch(groupsDaoProvider).watchMembers(groupId);
});

final isGroupMemberProvider = StreamProvider.family<bool, int>((ref, groupId) {
  return ref.watch(groupsDaoProvider).watchIsMember(groupId);
});

final groupForMentorProvider = StreamProvider.family<Group?, int>((ref, mentorId) {
  return ref.watch(groupsDaoProvider).watchGroupForMentor(mentorId);
});

// ── Health ──

final healthFacilitiesDaoProvider = Provider<HealthFacilitiesDao>((ref) {
  return ref.watch(appDatabaseProvider).healthFacilitiesDao;
});

final healthFacilitiesProvider = StreamProvider<List<HealthFacility>>((ref) {
  return ref.watch(healthFacilitiesDaoProvider).watchFacilities();
});

// ── AI Chat ──

final chatContentDaoProvider = Provider<ChatContentDao>((ref) {
  return ref.watch(appDatabaseProvider).chatContentDao;
});

final chatHistoryDaoProvider = Provider<ChatHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).chatHistoryDao;
});

/// The session the chat screen is currently reading/writing. Starts as the
/// most recently active session (or a fresh one) and is overridden when the
/// user taps "New chat" — see ai_chat_screen.dart.
final activeChatSessionProvider = FutureProvider<int>((ref) {
  return ref.watch(chatHistoryDaoProvider).getOrCreateActiveSession();
});

/// Reactive message history for [activeChatSessionProvider]'s session —
/// emits an empty list (rather than staying in AsyncLoading) until the
/// session id resolves, which is near-instant in practice.
final currentChatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final sessionId = ref.watch(activeChatSessionProvider).valueOrNull;
  if (sessionId == null) return Stream.value(const <ChatMessage>[]);
  return ref.watch(chatHistoryDaoProvider).watchMessages(sessionId);
});

final offlineChatServiceProvider = Provider<OfflineChatService>((ref) {
  return OfflineChatService(ref.watch(chatContentDaoProvider));
});

final chatContentSyncServiceProvider = Provider<ChatContentSyncService>((ref) {
  return ChatContentSyncService(ref.watch(chatContentDaoProvider));
});

final webLookupServiceProvider = Provider<WebLookupService>((ref) {
  return WebLookupService();
});

/// Fire-and-forget startup work for the chat feature. Watched once,
/// non-blockingly, from app.dart — must never delay first paint, so
/// nothing here is awaited before runApp:
/// 1. Re-apply assets/offline/offline_chat.json's curated content. Safe to
///    repeat every launch — upsertIntent replaces patterns wholesale and
///    only appends genuinely new response variants — so bundled content
///    corrections/additions reach existing installs without a schema
///    migration, on the very next launch after an app update.
/// 2. Pull any newer content-pack version from Firestore (silently a no-op
///    if offline — see ChatContentSyncService).
/// 3. Prune conversation history past the retention window.
final chatBootstrapProvider = FutureProvider<void>((ref) async {
  await seedChatContentFromAsset(ref.read(chatContentDaoProvider));
  await ref.read(chatContentSyncServiceProvider).sync();
  await ref.read(chatHistoryDaoProvider).pruneOlderThan(const Duration(days: 30));
});
