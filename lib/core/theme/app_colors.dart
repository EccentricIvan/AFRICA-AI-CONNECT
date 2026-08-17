import 'package:flutter/material.dart';

/// "Terracotta Blush" design tokens. All widget code should reference
/// these — no hardcoded hex in feature screens.
class AppColors {
  AppColors._();

  // Background: warm blush cream (flat — not a gradient in this palette)
  static const Color bgTop = Color(0xFFFAF1EC);
  static const Color bgBottom = Color(0xFFFAF1EC);

  // Brand — terracotta carries buttons, active nav, links
  static const Color primary = Color(0xFFC96F4A);
  static const Color primaryLight = Color(0xFFE0A98C);
  static const Color accent = Color(0xFFC96F4A);
  static const Color secondary = Color(0xFF2E8B8B);

  // Reward / points
  static const Color gold = Color(0xFFD4A24E);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF3A2E29);
  static const Color cardOverlay = Color(0x334A403B);

  // Text tiers — solid, not alpha, so contrast is guaranteed regardless
  // of what's behind them. textHint is the floor: never go lighter.
  static const Color textPrimary = Color(0xFF3A2E29);
  static const Color textSecondary = Color(0xFF4A403B);
  static const Color textHint = Color(0xFF6E5F57);
  static const Color textOnSurface = Color(0xFF3A2E29);

  static const Color border = Color(0xFFF0E2DA);

  // Pillar colors
  static const Color learnColor = Color(0xFF7C5CBF);
  static const Color earnColor = Color(0xFFC96F4A);
  static const Color growColor = Color(0xFF8B6F9E);
  static const Color thriveColor = Color(0xFFB4436C);

  // Category / feature icon colors
  static const Color skillsColor = Color(0xFF7C5CBF); // Digital Skills — violet
  static const Color financeColor = Color(
    0xFF2E8B8B,
  ); // Financial Literacy — teal
  static const Color marketplaceColor = Color(
    0xFFC96F4A,
  ); // Entrepreneurship — terracotta
  static const Color agricultureColor = Color(
    0xFF5E8C4A,
  ); // Agriculture — leaf green
  static const Color healthColor = Color(0xFFB4436C); // Health/Wellbeing — rose
  static const Color wellbeingColor = Color(0xFFB4436C);
  static const Color communityColor = Color(0xFF8B6F9E);
  static const Color mentorshipColor = Color(0xFFB4436C);
  static const Color jobsColor = Color(0xFF2E8B8B);
  static const Color chatColor = Color(0xFF5B8AA8);
  static const Color profileColor = Color(0xFFD4A24E);
  static const Color settingsColor = Color(0xFF8C7F73);

  // Status
  static const Color online = Color(0xFF5E8C4A);
  static const Color offline = Color(0xFFD4A24E);
}
