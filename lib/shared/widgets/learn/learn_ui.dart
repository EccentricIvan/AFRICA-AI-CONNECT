import 'package:flutter/material.dart';

/// Presentation tokens for Learn Premium redesign.
class LearnUi {
  LearnUi._();

  static const Color pageBg = Color(0xFFFAF8F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6D6D6D);
  static const Color accent = Color(0xFFF26B2D);
  static const Color accentDeep = Color(0xFFE85A1C);
  static const Color border = Color(0xFFECE8E3);
  static const Color success = Color(0xFF4D8B55);

  static const double radiusHero = 32;
  static const double radiusCard = 24;
  static const double radiusBtn = 28;
  static const double radiusChip = 16;

  static const String heroBackgroundAsset =
      'assets/branding/learn_background.png';

  static const String progressMascotAsset =
      'assets/branding/learn_progress_mascot.png';

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1B1B1B).withValues(alpha: 0.07),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get pillShadow => [
    BoxShadow(
      color: const Color(0xFF1B1B1B).withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
