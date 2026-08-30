import 'package:flutter/material.dart';

/// "Crystal Sky" design tokens — white-first canvas, crystal blue accents only.
class AppColors {
  const AppColors._({
    required this.bgTop,
    required this.bgBottom,
    required this.pageGradientMid,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.iconWell,
    required this.isDark,
  });

  final Color bgTop;
  final Color bgBottom;
  final Color pageGradientMid;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color iconWell;
  final bool isDark;

  Color get textOnSurface => textPrimary;
  Color get pageBg => bgBottom;
  Color get card => surface;

  static const AppColors light = AppColors._(
    bgTop: Color(0xFFFAFCFF),
    bgBottom: Color(0xFFFFFFFF),
    pageGradientMid: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF142840),
    textSecondary: Color(0xFF3D5A73),
    textHint: Color(0xFF6B8499),
    border: Color(0xFFE8F2FA),
    iconWell: Color(0xFFF3F9FD),
    isDark: false,
  );

  static const AppColors darkTheme = AppColors._(
    bgTop: Color(0xFF0A1018),
    bgBottom: Color(0xFF101820),
    pageGradientMid: Color(0xFF101820),
    surface: Color(0xFF1A2433),
    textPrimary: Color(0xFFE8F2FC),
    textSecondary: Color(0xFF9BB8D4),
    textHint: Color(0xFF6B8499),
    border: Color(0xFF2A4060),
    iconWell: Color(0xFF1E2D42),
    isDark: true,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static Color pageBackground(BuildContext context) =>
      of(context).isDark ? darkTheme.bgBottom : Colors.white;

  /// Whisper-blue at top edge only — most of the screen stays white.
  static BoxDecoration pageDecoration(BuildContext context) {
    final c = of(context);
    if (c.isDark) {
      return BoxDecoration(color: c.bgBottom);
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFAFCFF), Color(0xFFFFFFFF)],
        stops: [0.0, 0.18],
      ),
    );
  }

  // Brand
  static const Color primary = Color(0xFF2E96E8);
  static const Color primaryLight = Color(0xFF7EC8F5);
  static const Color accent = Color(0xFF2E96E8);
  static const Color accentDeep = Color(0xFF1B7FD4);
  static const Color secondary = Color(0xFF3BAFD4);

  static Color get accentGlow => primary.withValues(alpha: 0.24);

  static Color glassFill(BuildContext context, {bool strong = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (strong) {
      return dark
          ? const Color(0xFF1E2D42).withValues(alpha: 0.95)
          : const Color(0xFFFFFFFF);
    }
    return dark
        ? const Color(0xFF1E2D42).withValues(alpha: 0.85)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.95);
  }

  static Color glassBorderHighlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.90);

  static Color glassBorderDim(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A4060).withValues(alpha: 0.40)
          : const Color(0xFFE8F2FA);

  static const Color glassShadow = Color(0x141A4A7A);
  static const double glassBlurSigma = 12;
  static const double glassBlurSigmaHeavy = 16;

  static const Color gold = Color(0xFF6EC4FF);
  static const Color surfaceDark = Color(0xFF142840);
  static const Color cardOverlay = Color(0x33142840);

  static const Color learnColor = Color(0xFF4A8FE8);
  static const Color earnColor = Color(0xFF2E96E8);
  static const Color growColor = Color(0xFF3BAFD4);
  static const Color thriveColor = Color(0xFF5BB8E8);

  static const Color skillsColor = Color(0xFF4A8FE8);
  static const Color financeColor = Color(0xFF2EA8C4);
  static const Color marketplaceColor = Color(0xFF2E96E8);
  static const Color agricultureColor = Color(0xFF3DAA6D);
  static const Color healthColor = Color(0xFF6AACDE);
  static const Color wellbeingColor = Color(0xFF5BB8E8);
  static const Color communityColor = Color(0xFF7EB8E8);
  static const Color mentorshipColor = Color(0xFF5BB8E8);
  static const Color jobsColor = Color(0xFF4898D4);
  static const Color chatColor = Color(0xFF4DB3FF);
  static const Color profileColor = Color(0xFF6EC4FF);
  static const Color settingsColor = Color(0xFF6B8499);

  static const Color online = Color(0xFF3DAA6D);
  static const Color offline = Color(0xFF6EC4FF);

  /// Hero/card text wash over decorative PNG — brightness-aware.
  static List<Color> heroOverlayColors(BuildContext context) {
    if (of(context).isDark) {
      return [
        const Color(0xFF101820).withValues(alpha: 0.82),
        const Color(0xFF101820).withValues(alpha: 0.55),
        const Color(0xFF101820).withValues(alpha: 0.20),
        Colors.transparent,
      ];
    }
    return [
      Colors.white.withValues(alpha: 0.92),
      Colors.white.withValues(alpha: 0.72),
      Colors.white.withValues(alpha: 0.35),
      Colors.transparent,
    ];
  }

  static LinearGradient primaryButtonGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DB3FF), Color(0xFF2E96E8)],
  );

  static LinearGradient fabGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DB3FF), Color(0xFF1B7FD4)],
  );

  List<BoxShadow> softShadow(bool isDark) => isDark
      ? const []
      : const [
          BoxShadow(
            color: glassShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ];

  List<BoxShadow> navShadow(bool isDark) => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x1A1A4A7A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];
}
