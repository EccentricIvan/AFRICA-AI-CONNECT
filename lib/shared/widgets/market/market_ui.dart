import 'package:flutter/material.dart';

/// Presentation tokens for Marketplace Premium redesign (Markenzy) —
/// brightness-aware. Fetch the active palette via `MarketUi.of(context)`
/// rather than a static constant.
class MarketUi {
  const MarketUi._({
    required this.pageBg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.iconWell,
    required this.isDark,
  });

  final Color pageBg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color iconWell;
  final bool isDark;

  static const MarketUi light = MarketUi._(
    pageBg: Color(0xFFFCFAF8),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF202020),
    textSecondary: Color(0xFF666666),
    border: Color(0xFFEFE9E3),
    iconWell: Color(0xFFF8F0EA),
    isDark: false,
  );

  static const MarketUi darkTheme = MarketUi._(
    pageBg: Color(0xFF121212),
    card: Color(0xFF212121),
    textPrimary: Color(0xFFF2F0EE),
    textSecondary: Color(0xFFA6A19C),
    border: Color(0xFF322F2C),
    iconWell: Color(0xFF2A2622),
    isDark: true,
  );

  static MarketUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = Color(0xFFF28A1A);
  static const Color accentDeep = Color(0xFFE07812);

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
