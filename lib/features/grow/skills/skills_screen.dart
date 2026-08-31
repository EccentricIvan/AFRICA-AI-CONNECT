import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/learn/learn_category_card.dart';
import '../../../shared/widgets/learn/learn_course_card.dart';
import '../../../shared/widgets/learn/learn_header_bar.dart';
import '../../../shared/widgets/learn/learn_hero_card.dart';
import '../../../shared/widgets/learn/learn_insight_card.dart';
import '../../../shared/widgets/learn/learn_journey_timeline.dart';
import '../../../shared/widgets/learn/learn_progress_card.dart';
import '../../../shared/widgets/learn/learn_section_header.dart';
import 'course_topics_screen.dart';

IconData iconForCourseKey(String key) {
  switch (key) {
    case 'laptop_mac':
      return Icons.laptop_mac_outlined;
    case 'account_balance':
      return Icons.account_balance_outlined;
    case 'rocket_launch':
      return Icons.rocket_launch_outlined;
    case 'agriculture':
      return Icons.agriculture_outlined;
    case 'favorite':
      return Icons.favorite_outline;
    case 'emoji_events':
      return Icons.emoji_events_outlined;
    default:
      return Icons.auto_awesome_outlined;
  }
}

Color colorForCourseKey(String key) {
  switch (key) {
    case 'skills':
      return AppColors.skillsColor;
    case 'finance':
      return AppColors.financeColor;
    case 'earn':
      return AppColors.earnColor;
    case 'agriculture':
      return AppColors.agricultureColor;
    case 'health':
      return AppColors.healthColor;
    case 'community':
      return AppColors.communityColor;
    default:
      return AppColors.skillsColor;
  }
}

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  final _scrollController = ScrollController();
  final _continueKey = GlobalKey();
  final _categoriesKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openCourse(BuildContext context, int courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseTopicsScreen(courseId: courseId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    final coursesAsync = ref.watch(coursesProvider);
    final progressAsync = ref.watch(allCourseProgressProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.pageDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              LearnHeaderBar(
                title: t('skills'),
                subtitle: S.literal('Practical training to boost your career and business'),
                onBack: () => context.go('/'),
              ),
              Expanded(
                child: coursesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(child: Text(S.literal('Could not load skills content.'))),
                  data: (courses) {
                    final progressByCourseId = {
                      for (final p in progressAsync.valueOrNull ?? const <CourseProgressRow>[])
                        p.courseId: p,
                    };
                    final completedCount = progressByCourseId.values
                        .where((p) => p.status == 'completed')
                        .length;
                    final inProgress = courses
                        .where((c) => progressByCourseId[c.id]?.status == 'in_progress')
                        .toList();
                    final featured = inProgress.isNotEmpty ? inProgress : courses.take(3).toList();
                    final recommended =
                        courses.where((c) => progressByCourseId[c.id] == null).toList();

                    final points = statsAsync.valueOrNull?.totalPoints ?? 0;
                    final streak = statsAsync.valueOrNull?.currentStreakDays ?? 0;
                    final nextMilestone = ((points ~/ 100) + 1) * 100;

                    final journey = courses.map((c) {
                      final status = progressByCourseId[c.id]?.status;
                      return LearnJourneyItem(
                        title: c.title,
                        subtitle: c.subtitle,
                        status: status == 'completed'
                            ? LearnJourneyStatus.completed
                            : status == 'in_progress'
                                ? LearnJourneyStatus.current
                                : LearnJourneyStatus.next,
                      );
                    }).toList();

                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LearnHeroCard(
                            titleLine1: S.literal('Build skills.'),
                            titleLine2: S.literal('Build your future.'),
                            body: S.literal(
                              'Practical skills and training programmes designed for women — from digital literacy to leadership, all in your language.',
                            ),
                            primaryLabel: t('continue_learning'),
                            secondaryLabel: t('browse_topics'),
                            onPrimary: () => _scrollTo(_continueKey),
                            onSecondary: () => _scrollTo(_categoriesKey),
                          ),
                          const SizedBox(height: 20),
                          LearnProgressCard(
                            title: S.literal('Your Progress'),
                            coursesLabel: S.literal('Skills Completed'),
                            coursesValue: '$completedCount',
                            streakLabel: S.literal('Days Streak'),
                            streakValue: '$streak',
                            pointsLabel: S.literal('Points Earned'),
                            pointsValue: '$points',
                            milestoneLabel: t('next_milestone'),
                            milestoneHint: S.literal(
                              'Complete more topics to reach your next milestone',
                            ),
                            milestoneValue: '$points / $nextMilestone',
                            progress: nextMilestone == 0 ? 0 : points / nextMilestone,
                          ),
                          if (featured.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            KeyedSubtree(
                              key: _continueKey,
                              child: LearnSectionHeader(title: t('continue_learning')),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 148,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.hardEdge,
                                itemCount: featured.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final c = featured[i];
                                  final p = progressByCourseId[c.id];
                                  return LearnCourseCard(
                                    title: c.title,
                                    icon: iconForCourseKey(c.iconKey),
                                    lessonsLabel: '${c.lessonCount} ${t("lessons")}',
                                    progress: p?.progressPercent ?? 0,
                                    showProgress: p != null,
                                    onTap: () => _openCourse(context, c.id),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          KeyedSubtree(
                            key: _categoriesKey,
                            child: LearnSectionHeader(title: t('browse_topics')),
                          ),
                          const SizedBox(height: 14),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: courses.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.92,
                            ),
                            itemBuilder: (context, i) {
                              final c = courses[i];
                              return LearnCategoryCard(
                                title: c.title,
                                subtitle: c.subtitle,
                                icon: iconForCourseKey(c.iconKey),
                                lessonsLabel: '${c.lessonCount} ${t("lessons")}',
                                onTap: () => _openCourse(context, c.id),
                              );
                            },
                          ),
                          if (recommended.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            LearnSectionHeader(title: S.literal('Recommended')),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 128,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.hardEdge,
                                itemCount: recommended.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final c = recommended[i];
                                  return LearnCourseCard(
                                    title: c.title,
                                    icon: iconForCourseKey(c.iconKey),
                                    lessonsLabel: '${c.lessonCount} ${t("lessons")}',
                                    progress: 0,
                                    showProgress: false,
                                    onTap: () => _openCourse(context, c.id),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          LearnSectionHeader(title: S.literal('Your Journey')),
                          const SizedBox(height: 14),
                          LearnJourneyTimeline(items: journey),
                          const SizedBox(height: 28),
                          LearnSectionHeader(title: S.literal('Daily Insight')),
                          const SizedBox(height: 14),
                          LearnInsightCard(
                            title: t('ask_ai_assistant'),
                            body: t('ask_ai_assistant_desc'),
                            ctaLabel: S.literal('Read more'),
                            onTap: () => context.go('/ai-chat'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
