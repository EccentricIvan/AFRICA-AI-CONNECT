import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'learn_ui.dart';

/// Horizontal course card — same white/soft language as Browse Topics.
class LearnCourseCard extends StatelessWidget {
  const LearnCourseCard({
    super.key,
    required this.title,
    required this.icon,
    required this.lessonsLabel,
    this.progress = 0,
    this.showProgress = true,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String lessonsLabel;
  final double progress;
  final bool showProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return TapScale(
      borderRadius: LearnUi.radiusCard,
      onTap: onTap ?? () {},
      child: Container(
        width: 210,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: LearnUi.card,
          borderRadius: BorderRadius.circular(LearnUi.radiusCard),
          boxShadow: LearnUi.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: LearnUi.textPrimary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LearnUi.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lessonsLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: LearnUi.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (showProgress && progress > 0) ...[
              Row(
                children: [
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: LearnUi.accent,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: LearnUi.card,
                      shape: BoxShape.circle,
                      boxShadow: LearnUi.pillShadow,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: LearnUi.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: const Color(0xFFF0EBE6),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LearnUi.accent,
                  ),
                ),
              ),
            ] else ...[
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: LearnUi.card,
                    shape: BoxShape.circle,
                    boxShadow: LearnUi.pillShadow,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: LearnUi.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
