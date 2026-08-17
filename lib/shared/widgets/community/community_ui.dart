import 'package:flutter/material.dart';

/// Presentation tokens for Community's Premium redesign (Markenzy) —
/// same radius scale, shadow language, and neutral-card-with-accent-pop
/// approach as `MarketUi`/`LearnUi`/`ChatUi`, tuned to Community's own
/// violet/rose identity instead of Marketplace's orange.
class CommunityUi {
  CommunityUi._();

  static const Color pageBg = Color(0xFFFCFAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF202020);
  static const Color textSecondary = Color(0xFF666666);
  // Orange to stay uniform with Marketplace/Learn/Home — not a Community-
  // specific violet anymore.
  static const Color accent = Color(0xFFF28A1A);
  static const Color accentDeep = Color(0xFFE07812);
  static const Color border = Color(0xFFEDE7F0);
  static const Color iconWell = Color(0xFFF3EEF6);
  static const Color unread = Color(0xFFF28A1A);

  static const double radiusHero = 34;
  static const double radiusCard = 28;
  static const double radiusBtn = 28;
  static const double radiusChip = 16;

  // No community-specific photo asset exists yet — drop one in as
  // assets/branding/community_background.png and CommunityHeroCard picks
  // it up automatically.
  static const String heroBackgroundAsset =
      'assets/branding/community_background.png';

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
