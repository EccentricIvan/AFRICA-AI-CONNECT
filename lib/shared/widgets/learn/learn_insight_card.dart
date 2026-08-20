import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'learn_ui.dart';

class LearnInsightCard extends StatelessWidget {
  const LearnInsightCard({
    super.key,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return TapScale(
      borderRadius: LearnUi.radiusCard,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(LearnUi.radiusCard),
          border: Border.all(color: ui.border),
          boxShadow: ui.softShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LearnUi.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: ui.border),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                color: LearnUi.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: ui.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ctaLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: LearnUi.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
