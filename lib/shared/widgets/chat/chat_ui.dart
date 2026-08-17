import 'package:flutter/material.dart';

/// Presentation tokens for Chat Premium redesign (Markenzy).
class ChatUi {
  ChatUi._();

  static const Color pageBg = Color(0xFFFFF9F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color accent = Color(0xFFF28C28);
  static const Color accentDeep = Color(0xFFE07818);
  static const Color accentGold = Color(0xFFF6C36B);
  static const Color border = Color(0xFFF2E7DD);
  static const Color online = Color(0xFF4D8B55);
  static const Color userBubble = Color(0xFFFFF0E4);
  static const Color iconWell = Color(0xFFF8F0EA);

  static const double radiusCard = 24;
  static const double radiusHero = 28;
  static const double radiusBtn = 28;
  static const double radiusPill = 32;

  static const String pageBackgroundAsset =
      'assets/branding/chat_background.png';

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1F1F1F).withValues(alpha: 0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.28),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
