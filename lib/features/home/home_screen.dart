import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../db/providers/database_provider.dart';

/// Home presentation tokens aligned to Home_page.png.
/// Keeps app-wide AppColors for the shared warm background.
class _HomeUi {
  _HomeUi._();

  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6F6F6F);
  static const Color border = Color(0xFFECE7E2);
  static const Color accent = Color(0xFFD06F45);
  static const Color dark = Color(0xFF242424);
  static const Color success = Color(0xFF4D8B55);

  static const double radiusLg = 24;
  static const double radiusMd = 18;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1F1F1F).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _t(String key) => ref.watch(offlineLanguageServiceProvider).t(key);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _t('good_morning');
    if (hour < 17) return _t('good_afternoon');
    return _t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final profileName = ref.watch(currentUserProvider).valueOrNull?.name.trim();
    final userName =
        profileName == null || profileName.isEmpty ? _t('friend') : profileName;

    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ac.bgTop, ac.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _HomeAppBar(userName: userName, greeting: _greeting),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _HeroBanner(t: _t),
                      const SizedBox(height: 24),
                      _DailyTip(t: _t),
                      const SizedBox(height: 32),
                      _SectionLabel(_t('your_progress')),
                      const SizedBox(height: 16),
                      _ProgressRow(t: _t),
                      const SizedBox(height: 32),
                      _SectionLabel(_t('quick_actions')),
                      const SizedBox(height: 16),
                      _QuickActions(t: _t),
                      const SizedBox(height: 32),
                      _SectionLabel(_t('explore_pillars')),
                      const SizedBox(height: 16),
                      _PillarCards(t: _t),
                      const SizedBox(height: 32),
                      _SectionLabel(_t('all_services')),
                      const SizedBox(height: 16),
                      _ServicesGrid(t: _t),
                      const SizedBox(height: 40),
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

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.userName, required this.greeting});
  final String userName;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_HomeUi.accent, Color(0xFF2E8B8B)],
                ),
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _IconBtn(Icons.search_rounded, () {}),
          const SizedBox(width: 10),
          _NotificationBtn(),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x183A2E29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x123A2E29)),
        ),
      ),
    );
  }
}

class _NotificationBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconBtn(Icons.notifications_outlined, () {}),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _HomeUi.accent,
              shape: BoxShape.circle,
              border: Border.all(color: _HomeUi.card, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.t});
  final String Function(String) t;

  List<InlineSpan> _titleSpans(String title) {
    const base = TextStyle(
      fontFamily: 'Saira',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.15,
      letterSpacing: -0.4,
    );
    const accent = TextStyle(
      fontFamily: 'Saira',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _HomeUi.accent,
      height: 1.15,
      letterSpacing: -0.4,
    );

    final cleaned = title.replaceAll('\n', ' ').trim();
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return [TextSpan(text: cleaned, style: base)];
    }
    final last = parts.removeLast();
    return [
      TextSpan(text: '${parts.join(' ')} ', style: base),
      TextSpan(text: last, style: accent),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_HomeUi.radiusLg),
        boxShadow: _HomeUi.softShadow,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.online.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi, size: 12, color: AppColors.online),
                    const SizedBox(width: 4),
                    Text(
                      t('online'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.online,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.earnColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 13,
                      color: AppColors.earnColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '7 ${t('day_streak')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.earnColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t('hero_title'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('hero_subtitle'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/learn'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('continue_learning'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

class _HeroFloatIcon extends StatelessWidget {
  const _HeroFloatIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 17, color: _HomeUi.dark),
    );
  }
}

class _HeroDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.82, size.height * 0.78);
    final ring =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.08);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(origin, 36.0 * i, ring);
    }

    // Dotted Africa-ish silhouette on the right using seeded dots.
    final mapDots = <Offset>[
      const Offset(0.72, 0.18),
      const Offset(0.76, 0.14),
      const Offset(0.80, 0.16),
      const Offset(0.84, 0.20),
      const Offset(0.78, 0.24),
      const Offset(0.74, 0.28),
      const Offset(0.82, 0.28),
      const Offset(0.86, 0.32),
      const Offset(0.70, 0.34),
      const Offset(0.76, 0.36),
      const Offset(0.82, 0.38),
      const Offset(0.88, 0.40),
      const Offset(0.74, 0.44),
      const Offset(0.80, 0.46),
      const Offset(0.86, 0.48),
      const Offset(0.78, 0.52),
      const Offset(0.84, 0.54),
      const Offset(0.76, 0.58),
      const Offset(0.82, 0.60),
      const Offset(0.88, 0.58),
      const Offset(0.74, 0.64),
      const Offset(0.80, 0.66),
      const Offset(0.86, 0.68),
      const Offset(0.78, 0.72),
      const Offset(0.84, 0.74),
      const Offset(0.80, 0.80),
      const Offset(0.76, 0.78),
      const Offset(0.72, 0.48),
      const Offset(0.90, 0.36),
      const Offset(0.68, 0.42),
    ];
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < mapDots.length; i++) {
      final p = mapDots[i];
      paint.color = (i.isEven ? _HomeUi.accent : const Color(0xFFE8C4A8))
          .withValues(alpha: 0.45);
      canvas.drawCircle(
        Offset(size.width * p.dx, size.height * p.dy),
        2.1,
        paint,
      );
    }

    final rng = math.Random(3);
    for (var i = 0; i < 40; i++) {
      final x = size.width * (0.55 + rng.nextDouble() * 0.42);
      final y = size.height * (0.08 + rng.nextDouble() * 0.84);
      paint.color = _HomeUi.accent.withValues(
        alpha: 0.08 + rng.nextDouble() * 0.12,
      );
      canvas.drawCircle(Offset(x, y), 1.0 + rng.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DailyTip extends StatelessWidget {
  const _DailyTip({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final tips = [
      (t('tip_save'), Icons.lightbulb_outline, t('finance_tip')),
      (t('tip_sacco'), Icons.groups_rounded, t('community_tip')),
      (t('tip_photos'), Icons.camera_alt_outlined, t('business_tip')),
      (t('tip_water'), Icons.water_drop_outlined, t('health_tip')),
      (t('tip_digital'), Icons.computer, t('skills_tip')),
    ];

    final tip = tips[DateTime.now().day % tips.length];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: _HomeUi.card,
        borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
        border: Border.all(color: _HomeUi.border),
        boxShadow: _HomeUi.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.earnColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(tip.$2, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.$3,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earnColor.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.$1,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _HomeUi.textSecondary,
            size: 22,
          ),
        ],
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textHint,
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProgressItem(
        t('courses'),
        '3',
        Icons.menu_book_rounded,
        AppColors.learnColor,
        0.35,
      ),
      _ProgressItem(
        t('points'),
        '450',
        Icons.star_rounded,
        AppColors.gold,
        0.60,
      ),
      _ProgressItem(
        t('streak'),
        '7 ${t('days')}',
        Icons.local_fire_department,
        AppColors.accent,
        0.70,
      ),
    ];

    return Row(
      children:
          items.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x123A2E29),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x123A2E29)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        minHeight: 4,
                        backgroundColor: const Color(0x153A2E29),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _ProgressItem {
  const _ProgressItem(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.progress,
  );
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(t('ask_ai'), Icons.chat_rounded, AppColors.chatColor, '/ai-chat'),
      _Action(t('find_jobs'), Icons.work_rounded, AppColors.jobsColor, '/jobs'),
      _Action(
        t('learn'),
        Icons.menu_book_rounded,
        AppColors.learnColor,
        '/learn',
      ),
      _Action(
        t('marketplace'),
        Icons.storefront_rounded,
        AppColors.marketplaceColor,
        '/marketplace',
      ),
    ];

    return Row(
      children:
          actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: () => context.go(a.path),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        a.color.withValues(alpha: 0.2),
                        a.color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: a.color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: a.color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: a.color.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(a.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        a.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class _PillarCards extends StatelessWidget {
  const _PillarCards({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final pillars = [
      _Pillar(
        t('learn'),
        t('learn_desc'),
        Icons.menu_book_rounded,
        AppColors.learnColor,
        '/learn',
      ),
      _Pillar(
        t('earn'),
        t('earn_desc'),
        Icons.account_balance_wallet_rounded,
        AppColors.earnColor,
        '/marketplace',
      ),
      _Pillar(
        t('grow'),
        t('grow_desc'),
        Icons.trending_up_rounded,
        AppColors.growColor,
        '/mentorship',
      ),
      _Pillar(
        t('thrive'),
        t('thrive_desc'),
        Icons.favorite_rounded,
        AppColors.thriveColor,
        '/health',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children:
          pillars.map((p) {
            return GestureDetector(
              onTap: () => context.go(p.path),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      p.color.withValues(alpha: 0.18),
                      p.color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(p.icon, color: p.color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      p.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _Pillar {
  const _Pillar(
    this.label,
    this.subtitle,
    this.icon,
    this.tint,
    this.accent,
    this.path,
  );
  final String label;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color accent;
  final String path;
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ServiceItem(
        t('finance'),
        Icons.savings_rounded,
        AppColors.financeColor,
        '/financial',
      ),
      _ServiceItem(
        t('mentors'),
        Icons.diversity_1_rounded,
        AppColors.mentorshipColor,
        '/mentorship',
      ),
      _ServiceItem(t('jobs'), Icons.work_rounded, AppColors.jobsColor, '/jobs'),
      _ServiceItem(
        t('skills'),
        Icons.auto_awesome_rounded,
        AppColors.skillsColor,
        '/skills',
      ),
      _ServiceItem(
        t('health'),
        Icons.favorite_rounded,
        AppColors.healthColor,
        '/health',
      ),
      _ServiceItem(
        t('community'),
        Icons.people_rounded,
        AppColors.communityColor,
        '/community',
      ),
      _ServiceItem(
        t('wellbeing'),
        Icons.spa_rounded,
        AppColors.wellbeingColor,
        '/wellbeing',
      ),
      _ServiceItem(
        t('settings'),
        Icons.settings_rounded,
        AppColors.settingsColor,
        '/settings',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children:
          items.map((i) {
            return GestureDetector(
              onTap: () => context.go(i.path),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: i.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: i.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(i.icon, color: i.color, size: 26),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    i.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}
