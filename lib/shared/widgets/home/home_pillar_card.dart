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
    return TapScale(
      onTap: onTap,
      borderRadius: HomeUi.radiusCard,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.border),
          boxShadow: HomeUi.softShadow,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeUi.card, accent.withValues(alpha: 0.06)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Saira',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HomeUi.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: HomeUi.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
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
