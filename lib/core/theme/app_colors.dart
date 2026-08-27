import 'package:flutter/material.dart';

/// "Terracotta Blush" design tokens. All widget code should reference
/// these — no hardcoded hex in feature screens.
///
/// Surface/background/text/border tokens are brightness-aware: fetch the
/// active palette via `AppColors.of(context)` rather than a static
/// constant, since [light] and [darkTheme] aren't compile-time constants
/// of each other. Brand/pillar/category/status colors stay static — they
/// read fine as colorful accents against either surface.
class AppColors {
  const AppColors._({
    required this.bgTop,
    required this.bgBottom,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.isDark,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final bool isDark;

  Color get textOnSurface => textPrimary;

  static const AppColors light = AppColors._(
    bgTop: Color(0xFFFAF1EC),
    bgBottom: Color(0xFFFAF1EC),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF3A2E29),
    textSecondary: Color(0xFF4A403B),
    textHint: Color(0xFF6E5F57),
    border: Color(0xFFF0E2DA),
    isDark: false,
  );

  static const AppColors darkTheme = AppColors._(
    bgTop: Color(0xFF141414),
    bgBottom: Color(0xFF141414),
    surface: Color(0xFF232323),
    textPrimary: Color(0xFFF2F0EE),
    textSecondary: Color(0xFFCFC9C3),
    textHint: Color(0xFF9C9691),
    border: Color(0xFF322F2C),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  // Brand — terracotta carries buttons, active nav, links. Identical in
  // both themes.
  static const Color primary = Color(0xFFC96F4A);
  static const Color primaryLight = Color(0xFFE0A98C);
  static const Color accent = Color(0xFFC96F4A);
  static const Color secondary = Color(0xFF2E8B8B);

  // Reward / points
  static const Color gold = Color(0xFFD4A24E);

  // Legacy fixed-dark surface — used by glass_card/helpline_sheet for
  // overlays that are always dark regardless of app theme (e.g. text over
  // a photo), not the page surface itself.
  static const Color surfaceDark = Color(0xFF3A2E29);
  static const Color cardOverlay = Color(0x334A403B);

  // Pillar colors
  static const Color learnColor = Color(0xFF7C5CBF);
  static const Color earnColor = Color(0xFFC96F4A);
  static const Color growColor = Color(0xFF8B6F9E);
  static const Color thriveColor = Color(0xFFB4436C);

  // Category / feature icon colors
  static const Color skillsColor = Color(0xFF7C5CBF); // Digital Skills — violet
  static const Color financeColor = Color(0xFF2E8B8B); // Financial Literacy — teal
  static const Color marketplaceColor = Color(0xFFC96F4A); // Entrepreneurship — terracotta
  static const Color agricultureColor = Color(0xFF5E8C4A); // Agriculture — leaf green
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
