import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'learn_ui.dart';

class LearnCategoryCard extends StatelessWidget {
  const LearnCategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lessonsLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String lessonsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return TapScale(
      borderRadius: LearnUi.radiusCard,
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(LearnUi.radiusCard),
          boxShadow: ui.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ui.isDark ? const Color(0xFF2A2622) : const Color(0xFFF4F0EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: ui.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ui.textPrimary,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: ui.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              lessonsLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: LearnUi.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
