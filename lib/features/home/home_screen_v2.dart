import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme_provider.dart';
import '../../db/providers/database_provider.dart';
import '../../shared/widgets/home/home_community_card.dart';
import '../../shared/widgets/home/home_header_bar.dart';
import '../../shared/widgets/home/home_hero_card.dart';
import '../../shared/widgets/home/home_notifications_panel.dart';
import '../../shared/widgets/home/home_pillar_card.dart';
import '../../shared/widgets/home/home_progress_card.dart';
import '../../shared/widgets/home/home_quick_action_card.dart';
import '../../shared/widgets/home/home_section_header.dart';
import '../../shared/widgets/home/home_service_chip.dart';
import '../../shared/widgets/home/home_ui.dart';

/// Premium Home presentation (V3). Does not replace [HomeScreen] source file.
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  String _t(String key) => S.tr(context, ref, key);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _t('good_morning');
    if (hour < 17) return _t('good_afternoon');
    return _t('good_evening');
  }

  void _openNotifications(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: S.literal('Dismiss'),
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim, anim2) => const SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 78, right: 24, left: 24),
            child: HomeNotificationsPanel(),
          ),
        ),
      ),
      transitionBuilder: (ctx, animation, __, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final userName = user?.name ?? S.literal('Friend');
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: HomeUi.of(context).pageBg,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HomeHeaderBar(
                userName: userName,
                greeting: _greeting,
                avatarPath: user?.avatarPath,
                onAvatarTap: () => context.go('/profile'),
                isDarkMode: isDarkMode,
                onThemeToggle: () => ref
                    .read(themeModeProvider.notifier)
                    .set(isDarkMode ? ThemeMode.light : ThemeMode.dark),
                onNotificationsTap: () => _openNotifications(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeHeroCard(
                        title: _t('hero_title'),
                        subtitle: _t('hero_subtitle'),
                        onlineLabel: _t('online'),
                        streakLabel: '7 ${_t('day_streak')}',
                        ctaLabel: _t('continue_learning'),
                        onCta: () => context.go('/learn'),
                      ),
                      const SizedBox(height: 24),
                      HomeSectionHeader(
                        title: _t('your_progress'),
                        trailing: _t('see_all'),
                        onTrailingTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(t: _t),
                      const SizedBox(height: 24),
                      _CommunityTip(t: _t),
                      const SizedBox(height: 32),
                      HomeSectionHeader(title: _t('quick_actions')),
                      const SizedBox(height: 16),
                      _QuickActions(t: _t),
                      const SizedBox(height: 32),
                      HomeSectionHeader(title: _t('explore_pillars')),
                      const SizedBox(height: 14),
                      _Pillars(t: _t),
                      const SizedBox(height: 32),
                      HomeSectionHeader(
                        title: _t('all_services'),
                        trailing: _t('see_all'),
                        onTrailingTap: () {},
                      ),
                      const SizedBox(height: 14),
                      _Services(t: _t),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityTip extends StatelessWidget {
  const _CommunityTip({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final tips = [
      (t('tip_save'), Icons.lightbulb_outline, t('finance_tip')),
      (t('tip_sacco'), Icons.groups_outlined, t('community_tip')),
      (t('tip_photos'), Icons.camera_alt_outlined, t('business_tip')),
      (t('tip_water'), Icons.water_drop_outlined, t('health_tip')),
      (t('tip_digital'), Icons.computer_outlined, t('skills_tip')),
    ];
    final tip = tips[DateTime.now().day % tips.length];

    return HomeCommunityCard(title: tip.$3, description: tip.$1, icon: tip.$2);
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HomeProgressCard(
              kind: HomeProgressKind.courses,
              label: t('courses'),
              value: '3',
              progress: 0.30,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: HomeProgressCard(
              kind: HomeProgressKind.points,
              label: t('points'),
              value: '450',
              progress: 0.81,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: HomeProgressCard(
              kind: HomeProgressKind.streak,
              label: t('streak'),
              value: '7d',
              progress: 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        t('ask_ai'),
        Icons.chat_bubble_outline_rounded,
        HomeUi.askAi,
        '/ai-chat',
      ),
      (t('find_jobs'), Icons.work_outline_rounded, HomeUi.findJobs, '/jobs'),
      (t('learn'), Icons.menu_book_outlined, HomeUi.learnAction, '/learn'),
      (
        t('marketplace'),
        Icons.storefront_outlined,
        HomeUi.marketplaceAction,
        '/marketplace',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final a in actions)
          Expanded(
            child: HomeQuickActionCard(
              label: a.$1,
              icon: a.$2,
              iconColor: a.$3,
              onTap: () => context.go(a.$4),
            ),
          ),
      ],
    );
  }
}

class _Pillars extends StatelessWidget {
  const _Pillars({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final pillars = [
      (
        t('learn'),
        t('learn_desc'),
        Icons.menu_book_outlined,
        HomeUi.learn,
        '/learn',
      ),
      (
        t('earn'),
        t('earn_desc'),
        Icons.account_balance_wallet_outlined,
        HomeUi.earn,
        '/marketplace',
      ),
      (
        t('grow'),
        t('grow_desc'),
        Icons.show_chart_outlined,
        HomeUi.grow,
        '/mentorship',
      ),
      (
        t('thrive'),
        t('thrive_desc'),
        Icons.favorite_outline_rounded,
        HomeUi.thrive,
        '/health',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pillars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (context, index) {
        final p = pillars[index];
        return HomePillarCard(
          title: p.$1,
          description: p.$2,
          icon: p.$3,
          accent: p.$4,
          onTap: () => context.go(p.$5),
        );
      },
    );
  }
}

class _Services extends StatelessWidget {
  const _Services({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final items = [
      (t('finance'), Icons.account_balance_outlined, '/financial'),
      (t('mentors'), Icons.diversity_1_outlined, '/mentorship'),
      (t('jobs'), Icons.work_outline_rounded, '/jobs'),
      (t('skills'), Icons.auto_awesome_outlined, '/skills'),
      (t('health'), Icons.favorite_outline_rounded, '/health'),
      (t('community'), Icons.people_outline_rounded, '/community'),
      (t('wellbeing'), Icons.spa_outlined, '/wellbeing'),
      (t('settings'), Icons.settings_outlined, '/settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 52,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return HomeServiceChip(
          label: item.$1,
          icon: item.$2,
          onTap: () => context.go(item.$3),
        );
      },
    );
  }
}
