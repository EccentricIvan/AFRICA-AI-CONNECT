import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../shared/widgets/tap_scale.dart';

class LearnHubScreen extends ConsumerWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    final categories = [
      _Cat(t('cat_digital'), t('cat_digital_desc'), Icons.computer, AppColors.skillsColor, 8, progress: 0.4),
      _Cat(t('cat_finance_lit'), t('cat_finance_lit_desc'), Icons.account_balance, AppColors.financeColor, 6, progress: 0.15),
      _Cat(t('cat_entrepreneur'), t('cat_entrepreneur_desc'), Icons.rocket_launch, AppColors.earnColor, 10),
      _Cat(t('cat_agri'), t('cat_agri_desc'), Icons.agriculture, AppColors.agricultureColor, 7),
      _Cat(t('cat_health_nut'), t('cat_health_nut_desc'), Icons.favorite, AppColors.thriveColor, 5),
      _Cat(t('cat_leadership'), t('cat_leadership_desc'), Icons.emoji_events, AppColors.growColor, 4),
    ];

    final featured = categories.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _LearnAppBar(t: t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _LearnHero(t: t),
                    const SizedBox(height: 24),
                    _SectionLabel(t('featured_courses')),
                    const SizedBox(height: 12),
                    _FeaturedCourses(courses: featured),
                    const SizedBox(height: 24),
                    _SectionLabel(t('browse_topics')),
                    const SizedBox(height: 4),
                    Text(
                      t('practical_skills_sub'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 14),
                    ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryCard(cat: c, t: t),
                    )),
                    const SizedBox(height: 16),
                    _SectionLabel(t('ai_learning_assistant')),
                    const SizedBox(height: 4),
                    Text(
                      t('ai_learning_desc'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 14),
                    _AiCard(t: t, onTap: () => context.go('/ai-chat')),
                    const SizedBox(height: 32),
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

class _LearnAppBar extends StatelessWidget {
  const _LearnAppBar({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x183A2E29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x123A2E29)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.go('/'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('learn'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  t('learn_desc'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.learnColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.learnColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _LearnHero extends StatelessWidget {
  const _LearnHero({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.learnColor.withValues(alpha: 0.2),
            AppColors.skillsColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.learnColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('knowledge_is_power'),
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary, height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('knowledge_is_power_desc'),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatChip(Icons.menu_book_rounded, '6 ${t("courses")}', AppColors.learnColor),
                    const SizedBox(width: 8),
                    _StatChip(Icons.star_rounded, '450 ${t("points")}', AppColors.gold),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      t('next_milestone'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint),
                    ),
                    const Spacer(),
                    const Text(
                      '450 / 500',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const LinearProgressIndicator(
                    value: 0.9,
                    minHeight: 5,
                    backgroundColor: Color(0x1A3A2E29),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.learnColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.learnColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.learnColor, size: 30),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.cat, required this.t});
  final _Cat cat;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: 18,
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x1F3A2E29)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: cat.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cat.title,
                                      style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${cat.count} ${t("lessons")}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.subtitle,
                                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (cat.progress > 0) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: cat.progress,
                                    minHeight: 3,
                                    backgroundColor: const Color(0x1A3A2E29),
                                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Color(0x553A2E29), size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCourses extends StatelessWidget {
  const _FeaturedCourses({required this.courses});
  final List<_Cat> courses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = courses[i];
          return TapScale(
            borderRadius: 20,
            onTap: () {},
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.color.withValues(alpha: 0.85), c.color],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: c.color.withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(c.icon, color: Colors.white, size: 19),
                  ),
                  const Spacer(),
                  Text(
                    c.title,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${c.count} lessons',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.t, required this.onTap});
  final String Function(String) t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.chatColor.withValues(alpha: 0.2),
              AppColors.primary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.chatColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.chatColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.chatColor.withValues(alpha: 0.4),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('ask_ai_assistant'),
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('ask_ai_assistant_desc'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.chatColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
        color: AppColors.textHint,
      ),
    );
  }
}

class _Cat {
  const _Cat(this.title, this.subtitle, this.icon, this.color, this.count, {this.progress = 0});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final double progress;
}
