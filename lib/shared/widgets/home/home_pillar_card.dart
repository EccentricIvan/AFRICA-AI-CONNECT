import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'home_ui.dart';

class HomePillarCard extends StatelessWidget {
  const HomePillarCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return TapScale(
      onTap: onTap,
      borderRadius: HomeUi.radiusCard,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: ui.border),
          boxShadow: ui.softShadow,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ui.card,
              accent.withValues(alpha: ui.isDark ? 0.14 : 0.06),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Saira',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ui.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: ui.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
