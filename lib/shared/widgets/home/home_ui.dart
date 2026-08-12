import 'package:flutter/material.dart';

/// Presentation tokens for Home Premium Visual Pass (V3).
class HomeUi {
  HomeUi._();

  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3EEE8);
  static const Color pageBg = Color(0xFFFAF8F6);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFECE8E3);
  static const Color accent = Color(0xFFF26B2D);
  static const Color accentDeep = Color(0xFFE85A1C);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color success = Color(0xFF4D8B55);

  // Pillar icon-only accents (white card backgrounds).
  static const Color learn = Color(0xFF4A6FA5);
  static const Color earn = Color(0xFFC4783A);
  static const Color grow = Color(0xFF4D8B55);
  static const Color thrive = Color(0xFFD65C6A);

  static const Color askAi = Color(0xFF2E8B8B);
  static const Color findJobs = Color(0xFFF26B2D);
  static const Color learnAction = Color(0xFF4A6FA5);
  static const Color marketplaceAction = Color(0xFF7C5CBF);

  static const double radiusHero = 32;
  static const double radiusCard = 24;
  static const double radiusBtn = 20;
  static const double radiusChip = 18;
  static const double radiusNav = 32;
  static const double radiusPill = 16;

  static const String heroBackgroundAsset =
      'assets/branding/card_background_light.png';

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}
