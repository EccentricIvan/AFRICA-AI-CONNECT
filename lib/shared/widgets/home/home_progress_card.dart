import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'home_ui.dart';

enum HomeProgressKind { courses, points, streak }

/// Compact light progress cards — equal height, three-in-a-row, no overflow.
class HomeProgressCard extends StatelessWidget {
  const HomeProgressCard({
    super.key,
    required this.kind,
    required this.label,
    required this.value,
    required this.progress,
  });

  final HomeProgressKind kind;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = switch (kind) {
      HomeProgressKind.courses => (
          const Color(0xFF7BA8E0),
          Icons.menu_book_rounded,
          '↑ 20%',
          'Keep learning',
        ),
      HomeProgressKind.points => (
          const Color(0xFFF0A878),
          Icons.star_rounded,
          '↑ 12%',
          'Awesome progress!',
        ),
      HomeProgressKind.streak => (
          const Color(0xFFE89A9A),
          Icons.local_fire_department_rounded,
          '↑ 1d',
          "You're on fire!",
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: HomeUi.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeUi.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HomeUi.card,
            theme.$1.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlowIcon(icon: theme.$2, color: theme.$1),
              const Spacer(),
              _TrendBadge(text: theme.$3, color: theme.$1),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Saira',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: HomeUi.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: HomeUi.textPrimary,
            ),
          ),
          Text(
            theme.$4,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, color: HomeUi.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: switch (kind) {
              HomeProgressKind.courses => _CoursesFooter(
                  progress: progress,
                  color: theme.$1,
                  value: value,
                ),
              HomeProgressKind.points => _PointsFooter(
                  progress: progress,
                  color: theme.$1,
                ),
              HomeProgressKind.streak => _StreakFooter(color: theme.$1),
            },
          ),
        ],
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: color, size: 12),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CoursesFooter extends StatelessWidget {
  const _CoursesFooter({
    required this.progress,
    required this.color,
    required this.value,
  });

  final double progress;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final left = math.max(0, 12 - (int.tryParse(value) ?? 3));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$pct%',
              style: const TextStyle(fontSize: 8, color: HomeUi.textSecondary),
            ),
            const Spacer(),
            Text(
              '$left left',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _Bar(progress: progress, color: color),
          ),
        ),
      ],
    );
  }
}

class _PointsFooter extends StatelessWidget {
  const _PointsFooter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ring = (progress * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 11, color: color),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Next 550',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: HomeUi.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: color,
                label: '$ring%',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakFooter extends StatelessWidget {
  const _StreakFooter({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const done = [true, true, true, true, true, false, false];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final size = ((c.maxWidth - 6 * 2) / 7).clamp(10.0, 14.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    Container(
                      width: size,
                      height: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done[i]
                            ? color.withValues(alpha: 0.85)
                            : color.withValues(alpha: 0.12),
                      ),
                      child: done[i]
                          ? Icon(
                              Icons.check,
                              size: size * 0.55,
                              color: Colors.white,
                            )
                          : Text(
                              days[i],
                              style: TextStyle(
                                fontSize: size * 0.45,
                                fontWeight: FontWeight.w700,
                                color: color.withValues(alpha: 0.55),
                              ),
                            ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 10, color: color),
            const SizedBox(width: 2),
            const Expanded(
              child: Text(
                'Best: 12d',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 8, color: HomeUi.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          height: 3.5,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: c.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.label,
  });

  final double progress;
  final Color color;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 6,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.label != label;
}
