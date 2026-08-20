import 'package:flutter/material.dart';

/// Presentation tokens for Chat Premium redesign (Markenzy) —
/// brightness-aware. Fetch the active palette via `ChatUi.of(context)`
/// rather than a static constant.
class ChatUi {
  const ChatUi._({
    required this.pageBg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.userBubble,
    required this.iconWell,
    required this.isDark,
  });

  final Color pageBg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color userBubble;
  final Color iconWell;
  final bool isDark;

  static const ChatUi light = ChatUi._(
    pageBg: Color(0xFFFFF9F4),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F1F1F),
    textSecondary: Color(0xFF6B6B6B),
    border: Color(0xFFF2E7DD),
    userBubble: Color(0xFFFFF0E4),
    iconWell: Color(0xFFF8F0EA),
    isDark: false,
  );

  static const ChatUi darkTheme = ChatUi._(
    pageBg: Color(0xFF121212),
    card: Color(0xFF212121),
    textPrimary: Color(0xFFF2F0EE),
    textSecondary: Color(0xFFA6A19C),
    border: Color(0xFF322F2C),
    userBubble: Color(0xFF3A2A1E),
    iconWell: Color(0xFF2A2622),
    isDark: true,
  );

  static ChatUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = Color(0xFFF28C28);
  static const Color accentDeep = Color(0xFFE07818);
  static const Color accentGold = Color(0xFFF6C36B);
  static const Color online = Color(0xFF4D8B55);

  static const double radiusCard = 24;
  static const double radiusHero = 28;
  static const double radiusBtn = 28;
  static const double radiusPill = 32;

  static const String pageBackgroundAsset =
      'assets/branding/chat_background.png';

  List<BoxShadow> get softShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF1F1F1F).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ];

  List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.28),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}
