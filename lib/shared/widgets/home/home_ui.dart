import 'package:flutter/material.dart';

/// Presentation tokens for Home Premium Visual Pass (V3) — now brightness-
/// aware. Surfaces/text/border swap between [light] and [darkTheme]; brand
/// and pillar accent colors stay identical in both (they're colorful pops
/// against a card, not a background, so they read fine either way).
/// Widgets fetch the active palette via `HomeUi.of(context)` instead of
/// static constants, since the two variants aren't compile-time constants
/// of each other.
class HomeUi {
  const HomeUi._({
    required this.card,
    required this.surface,
    required this.pageBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.isDark,
  });

  final Color card;
  final Color surface;
  final Color pageBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final bool isDark;

  static const HomeUi light = HomeUi._(
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF3EEE8),
    pageBg: Color(0xFFFAF8F6),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    border: Color(0xFFECE8E3),
    isDark: false,
  );

  static const HomeUi darkTheme = HomeUi._(
    card: Color(0xFF212121),
    surface: Color(0xFF1A1A1A),
    pageBg: Color(0xFF121212),
    textPrimary: Color(0xFFF2F0EE),
    textSecondary: Color(0xFFA6A19C),
    border: Color(0xFF322F2C),
    isDark: true,
  );

  static HomeUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  // Brand/pillar/status accents — identical in both themes.
  static const Color accent = Color(0xFFF26B2D);
  static const Color accentDeep = Color(0xFFE85A1C);
  static const Color dark = Color(0xFF1A1A1A);
  static const Color success = Color(0xFF4D8B55);

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

  // Shadows barely register against a dark surface and just look like a
  // muddy halo — cards lean on [border] alone for definition in dark mode.
  List<BoxShadow> get softShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ];

  List<BoxShadow> get navShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ];
}
