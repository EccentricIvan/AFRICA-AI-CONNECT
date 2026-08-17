import 'package:flutter/material.dart';

/// Presentation tokens for Marketplace Premium redesign (Markenzy).
class MarketUi {
  MarketUi._();

  static const Color pageBg = Color(0xFFFCFAF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF202020);
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFFF28A1A);
  static const Color accentDeep = Color(0xFFE07812);
  static const Color border = Color(0xFFEFE9E3);
  static const Color iconWell = Color(0xFFF8F0EA);

  static const double radiusHero = 34;
  static const double radiusCard = 28;
  static const double radiusBtn = 28;
  static const double radiusChip = 16;

  static const String heroBackgroundAsset =
      'assets/branding/market_background.png';

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF202020).withValues(alpha: 0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get pillShadow => [
    BoxShadow(
      color: const Color(0xFF202020).withValues(alpha: 0.07),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
