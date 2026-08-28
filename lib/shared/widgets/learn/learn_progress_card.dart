import 'package:flutter/material.dart';
import 'learn_ui.dart';

/// "Your Learning Progress" card matching the Learn premium mock.
class LearnProgressCard extends StatelessWidget {
  const LearnProgressCard({
    super.key,
    required this.title,
    required this.coursesLabel,
    required this.coursesValue,
    required this.streakLabel,
    required this.streakValue,
    required this.pointsLabel,
    required this.pointsValue,
    required this.milestoneLabel,
    required this.milestoneHint,
    required this.milestoneValue,
    required this.progress,
  });

  final String title;
  final String coursesLabel;
  final String coursesValue;
  final String streakLabel;
  final String streakValue;
  final String pointsLabel;
  final String pointsValue;
  final String milestoneLabel;
  final String milestoneHint;
  final String milestoneValue;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(LearnUi.radiusCard),
        boxShadow: ui.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ui.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: LearnUi.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _ProgressMascot(),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.menu_book_outlined,
                        value: coursesValue,
                        label: coursesLabel,
                      ),
                    ),
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.local_fire_department_outlined,
                        value: streakValue,
                        label: streakLabel,
                      ),
                    ),
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.star_outline_rounded,
                        value: pointsValue,
                        label: pointsLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestoneLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ui.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      milestoneHint,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: ui.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                milestoneValue,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: LearnUi.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MilestoneBar(progress: progress.clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: LearnUi.accent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Saira',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ui.textPrimary,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: ui.textSecondary,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumb = 22.0;
        final trackW = constraints.maxWidth;
        final fillW =
            ((trackW - thumb) * progress).clamp(0.0, trackW - thumb);

        return SizedBox(
          height: thumb,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBE6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: fillW + thumb / 2,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: LearnUi.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Positioned(
                left: fillW,
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: LearnUi.of(context).card,
                    shape: BoxShape.circle,
                    border: Border.all(color: LearnUi.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: LearnUi.accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: LearnUi.accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressMascot extends StatelessWidget {
  const _ProgressMascot();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Image.asset(
        LearnUi.progressMascotAsset,
        width: 78,
        height: 78,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
