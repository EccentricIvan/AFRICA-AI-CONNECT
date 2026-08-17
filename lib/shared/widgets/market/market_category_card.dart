import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'market_ui.dart';

class MarketCategoryCard extends StatelessWidget {
  const MarketCategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: MarketUi.radiusCard,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: MarketUi.card,
          borderRadius: BorderRadius.circular(MarketUi.radiusCard),
          boxShadow: MarketUi.softShadow,
          border: Border.all(
            color:
                selected ? accent.withValues(alpha: 0.55) : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: MarketUi.iconWell,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MarketUi.textPrimary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
