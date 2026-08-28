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
  String _t(String key) => S.tr(context, ref, key);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _t('good_morning');
    if (hour < 17) return _t('good_afternoon');
    return _t('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final userName =
        ref.watch(currentUserProvider).valueOrNull?.name ?? S.literal('Friend');

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
                    fontFamily: 'Saira',
                    fontSize: 20,
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
                    fontWeight: FontWeight.w400,
                    color: _HomeUi.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _HomeUi.textPrimary,
                    height: 1.15,
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
    return Material(
      color: _HomeUi.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _HomeUi.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _HomeUi.border),
            boxShadow: _HomeUi.softShadow,
          ),
          child: Icon(icon, color: _HomeUi.textPrimary, size: 22),
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
          top: 8,
          right: 8,
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.65, -0.15),
                  radius: 1.15,
                  colors: [
                    _HomeUi.accent.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _HeroDecorPainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 14, 22),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _HeroPill(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: _HomeUi.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t('online'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HeroPill(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    size: 13,
                                    color: _HomeUi.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '7 ${t('day_streak')}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text.rich(
                          TextSpan(children: _titleSpans(t('hero_title'))),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t('hero_subtitle'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Material(
                          color: _HomeUi.accent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => context.go('/learn'),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t('continue_learning'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    flex: 7,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 132,
                        height: 168,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 4,
                              right: 8,
                              child: _HeroFloatIcon(Icons.menu_book_rounded),
                            ),
                            Positioned(
                              top: 52,
                              right: 52,
                              child: _HeroFloatIcon(Icons.school_rounded),
                            ),
                            Positioned(
                              top: 96,
                              right: 0,
                              child: _HeroFloatIcon(Icons.show_chart_rounded),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 36,
                              child: _HeroFloatIcon(
                                Icons.account_balance_wallet_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    final ring = Paint()
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
      paint.color = _HomeUi.accent.withValues(alpha: 0.08 + rng.nextDouble() * 0.12);
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
            decoration: const BoxDecoration(
              color: _HomeUi.accent,
              shape: BoxShape.circle,
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
                  style: const TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _HomeUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.$1,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _HomeUi.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
        letterSpacing: 1.15,
        color: _HomeUi.textSecondary,
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
        _HomeUi.dark,
        0.35,
      ),
      _ProgressItem(
        t('points'),
        '450',
        Icons.star_rounded,
        _HomeUi.accent,
        0.60,
      ),
      _ProgressItem(
        t('streak'),
        '7d',
        Icons.local_fire_department_rounded,
        _HomeUi.accent,
        0.80,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              decoration: BoxDecoration(
                color: _HomeUi.card,
                borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
                border: Border.all(color: _HomeUi.border),
                boxShadow: _HomeUi.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _HomeUi.dark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[i].icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    items[i].value,
                    style: const TextStyle(
                      fontFamily: 'Saira',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _HomeUi.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _HomeUi.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: items[i].progress,
                      minHeight: 5,
                      backgroundColor: _HomeUi.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(items[i].color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
      _Action(t('ask_ai'), Icons.chat_bubble_outline_rounded, '/ai-chat'),
      _Action(t('find_jobs'), Icons.work_outline_rounded, '/jobs'),
      _Action(t('learn'), Icons.menu_book_outlined, '/learn'),
      _Action(t('marketplace'), Icons.storefront_outlined, '/marketplace'),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: const Color(0xFFF3EEE8),
              borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
              child: InkWell(
                onTap: () => context.go(actions[i].path),
                borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEE8),
                    borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
                    border: Border.all(color: _HomeUi.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        actions[i].icon,
                        color: _HomeUi.textPrimary,
                        size: 24,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        actions[i].label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _HomeUi.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
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
        Icons.menu_book_outlined,
        const Color(0xFFF7F5F2),
        _HomeUi.dark,
        '/learn',
      ),
      _Pillar(
        t('earn'),
        t('earn_desc'),
        Icons.account_balance_wallet_outlined,
        const Color(0xFFF8EDE6),
        _HomeUi.accent,
        '/marketplace',
      ),
      _Pillar(
        t('grow'),
        t('grow_desc'),
        Icons.trending_up_rounded,
        const Color(0xFFEDF4EA),
        _HomeUi.success,
        '/mentorship',
      ),
      _Pillar(
        t('thrive'),
        t('thrive_desc'),
        Icons.favorite_outline_rounded,
        const Color(0xFFF8ECE8),
        const Color(0xFFC45B4A),
        '/health',
      ),
    ];

    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pillars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = pillars[index];
          return SizedBox(
            width: 150,
            child: Material(
              color: p.tint,
              borderRadius: BorderRadius.circular(_HomeUi.radiusLg),
              child: InkWell(
                onTap: () => context.go(p.path),
                borderRadius: BorderRadius.circular(_HomeUi.radiusLg),
                child: Ink(
                  decoration: BoxDecoration(
                    color: p.tint,
                    borderRadius: BorderRadius.circular(_HomeUi.radiusLg),
                    border: Border.all(color: _HomeUi.border),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(p.icon, color: p.accent, size: 22),
                      const Spacer(),
                      Text(
                        p.label,
                        style: const TextStyle(
                          fontFamily: 'Saira',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _HomeUi.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _HomeUi.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
      _ServiceItem(t('finance'), Icons.savings_outlined, '/financial'),
      _ServiceItem(t('mentors'), Icons.diversity_1_outlined, '/mentorship'),
      _ServiceItem(t('jobs'), Icons.work_outline_rounded, '/jobs'),
      _ServiceItem(t('skills'), Icons.auto_awesome_outlined, '/skills'),
      _ServiceItem(t('health'), Icons.favorite_outline_rounded, '/health'),
      _ServiceItem(t('community'), Icons.people_outline_rounded, '/community'),
      _ServiceItem(t('wellbeing'), Icons.spa_outlined, '/wellbeing'),
      _ServiceItem(t('settings'), Icons.settings_outlined, '/settings'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.7,
      ),
      itemBuilder: (context, index) {
        final i = items[index];
        return Material(
          color: const Color(0xFFF3EEE8),
          borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
          child: InkWell(
            onTap: () => context.go(i.path),
            borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEE8),
                borderRadius: BorderRadius.circular(_HomeUi.radiusMd),
                border: Border.all(color: _HomeUi.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(i.icon, color: _HomeUi.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _HomeUi.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}
