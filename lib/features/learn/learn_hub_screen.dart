import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../shared/widgets/learn/learn_category_card.dart';
import '../../shared/widgets/learn/learn_course_card.dart';
import '../../shared/widgets/learn/learn_header_bar.dart';
import '../../shared/widgets/learn/learn_hero_card.dart';
import '../../shared/widgets/learn/learn_insight_card.dart';
import '../../shared/widgets/learn/learn_journey_timeline.dart';
import '../../shared/widgets/learn/learn_progress_card.dart';
import '../../shared/widgets/learn/learn_section_header.dart';
import '../../shared/widgets/learn/learn_tool_chip.dart';
import '../../shared/widgets/learn/learn_ui.dart';

class LearnHubScreen extends ConsumerStatefulWidget {
  const LearnHubScreen({super.key});

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
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

  List<LearnJourneyItem> _journeyFrom(List<_Cat> categories) {
    var foundCurrent = false;
    return categories.map((c) {
      if (c.progress > 0) {
        return LearnJourneyItem(
          title: c.title,
          subtitle: c.subtitle,
          status: LearnJourneyStatus.completed,
        );
      }
      if (!foundCurrent) {
        foundCurrent = true;
        return LearnJourneyItem(
          title: c.title,
          subtitle: c.subtitle,
          status: LearnJourneyStatus.current,
        );
      }
      return LearnJourneyItem(
        title: c.title,
        subtitle: c.subtitle,
        status: LearnJourneyStatus.next,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    final categories = [
      _Cat(
        t('cat_digital'),
        t('cat_digital_desc'),
        Icons.laptop_mac_outlined,
        8,
        progress: 0.6,
      ),
      _Cat(
        t('cat_finance_lit'),
        t('cat_finance_lit_desc'),
        Icons.account_balance_outlined,
        6,
        progress: 0.4,
      ),
      _Cat(
        t('cat_entrepreneur'),
        t('cat_entrepreneur_desc'),
        Icons.rocket_launch_outlined,
        10,
      ),
      _Cat(t('cat_agri'), t('cat_agri_desc'), Icons.agriculture_outlined, 7),
      _Cat(
        t('cat_health_nut'),
        t('cat_health_nut_desc'),
        Icons.favorite_outline,
        5,
      ),
      _Cat(
        t('cat_leadership'),
        t('cat_leadership_desc'),
        Icons.emoji_events_outlined,
        4,
      ),
    ];

    final continueCourses = categories.where((c) => c.progress > 0).toList();
    final featured =
        continueCourses.isNotEmpty
            ? continueCourses
            : categories.take(3).toList();
    final recommended = categories.where((c) => c.progress == 0).toList();
    final journey = _journeyFrom(categories);

    final tools = <(String, IconData)>[
      (S.literal('Downloads'), Icons.download_outlined),
      (S.literal('Certificates'), Icons.workspace_premium_outlined),
      (S.literal('Bookmarks'), Icons.bookmark_border_rounded),
      (t('offline'), Icons.offline_bolt_outlined),
      (S.literal('Notes'), Icons.sticky_note_2_outlined),
      (S.literal('History'), Icons.history_rounded),
    ];

    return Scaffold(
      backgroundColor: LearnUi.of(context).pageBg,
      body: SafeArea(
        child: Column(
          children: [
            LearnHeaderBar(
              title: t('learn'),
              subtitle: t('learn_desc'),
              onBack: () => context.go('/'),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LearnHeroCard(
                      titleLine1: S.literal('Keep learning.'),
                      titleLine2: S.literal('Keep growing.'),
                      body: t('knowledge_is_power_desc'),
                      primaryLabel: t('continue_learning'),
                      secondaryLabel: t('browse_topics'),
                      onPrimary: () => _scrollTo(_continueKey),
                      onSecondary: () => _scrollTo(_categoriesKey),
                    ),
                    const SizedBox(height: 20),
                    LearnProgressCard(
                      title: S.literal('Your Learning Progress'),
                      coursesLabel: S.literal('Courses Completed'),
                      coursesValue: '6',
                      streakLabel: S.literal('Days Streak'),
                      streakValue: '7',
                      pointsLabel: S.literal('Points Earned'),
                      pointsValue: '450',
                      milestoneLabel: t('next_milestone'),
                      milestoneHint: S.literal(
                          'Complete 2 more lessons to reach your next milestone'),
                      milestoneValue: '450 / 500',
                      progress: 0.9,
                    ),
                    const SizedBox(height: 28),
                    KeyedSubtree(
                      key: _continueKey,
                      child: LearnSectionHeader(
                        title: t('continue_learning'),
                        trailing: t('see_all'),
                        onTrailingTap: () {},
                      ),
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
                          return LearnCourseCard(
                            title: c.title,
                            icon: c.icon,
                            lessonsLabel: '${c.count} ${t("lessons")}',
                            progress: c.progress,
                            showProgress: true,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    KeyedSubtree(
                      key: _categoriesKey,
                      child: LearnSectionHeader(
                        title: t('browse_topics'),
                        trailing: t('see_all'),
                        onTrailingTap: () {},
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.92,
                          ),
                      itemBuilder: (context, i) {
                        final c = categories[i];
                        return LearnCategoryCard(
                          title: c.title,
                          subtitle: c.subtitle,
                          icon: c.icon,
                          lessonsLabel: '${c.count} ${t("lessons")}',
                          onTap: () {},
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    LearnSectionHeader(
                      title: S.literal('Recommended'),
                      trailing: t('see_all'),
                      onTrailingTap: () {},
                    ),
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
                            icon: c.icon,
                            lessonsLabel: '${c.count} ${t("lessons")}',
                            progress: 0,
                            showProgress: false,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    LearnSectionHeader(title: S.literal('Learning Journey')),
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
                    const SizedBox(height: 28),
                    LearnSectionHeader(title: S.literal('Quick Tools')),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tools.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                          ),
                      itemBuilder: (context, i) {
                        final tool = tools[i];
                        return LearnToolChip(
                          label: tool.$1,
                          icon: tool.$2,
                          onTap: () {},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cat {
  const _Cat(
    this.title,
    this.subtitle,
    this.icon,
    this.count, {
    this.progress = 0,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final double progress;
}
