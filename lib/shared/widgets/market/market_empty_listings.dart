import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'market_ui.dart';

class MarketEmptyListings extends StatelessWidget {
  const MarketEmptyListings({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
    this.showClearFilter = false,
    this.clearLabel,
    this.onClear,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;
  final bool showClearFilter;
  final String? clearLabel;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ui = MarketUi.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(MarketUi.radiusCard),
        boxShadow: ui.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ui.iconWell,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 34,
              color: MarketUi.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Saira',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ui.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ui.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (showClearFilter && onClear != null) ...[
            TextButton(
              onPressed: onClear,
              child: Text(
                clearLabel ?? 'Clear filter',
                style: const TextStyle(
                  color: MarketUi.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          TapScale(
            borderRadius: MarketUi.radiusBtn,
            onTap: onCta,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MarketUi.accent, MarketUi.accentDeep],
                ),
                borderRadius: BorderRadius.circular(MarketUi.radiusBtn),
                boxShadow: [
                  BoxShadow(
                    color: MarketUi.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    ctaLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
