import 'dart:io';

import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'market_ui.dart';

class MarketListingCard extends StatelessWidget {
  const MarketListingCard({
    super.key,
    required this.title,
    required this.sellerLine,
    required this.priceLabel,
    required this.fallbackIcon,
    this.imagePath,
    this.onTap,
  });

  final String title;
  final String sellerLine;
  final String priceLabel;
  final IconData fallbackIcon;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: MarketUi.radiusCard,
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MarketUi.card,
          borderRadius: BorderRadius.circular(MarketUi.radiusCard),
          boxShadow: MarketUi.softShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 64,
                child: imagePath != null
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Fallback(icon: fallbackIcon),
                      )
                    : _Fallback(icon: fallbackIcon),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MarketUi.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sellerLine,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MarketUi.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    priceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MarketUi.accent,
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

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MarketUi.iconWell,
      child: Icon(icon, color: MarketUi.accent, size: 28),
    );
  }
}
