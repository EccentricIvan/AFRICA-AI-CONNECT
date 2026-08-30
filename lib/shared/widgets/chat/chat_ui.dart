import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    pageBg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF142840),
    textSecondary: Color(0xFF3D5A73),
    border: Color(0xFFE8F2FA),
    userBubble: Color(0xFFF3F9FD),
    iconWell: Color(0xFFF3F9FD),
    isDark: false,
  );

  static const ChatUi darkTheme = ChatUi._(
    pageBg: Color(0xFF101820),
    card: Color(0xFF1A2433),
    textPrimary: Color(0xFFE8F2FC),
    textSecondary: Color(0xFF9BB8D4),
    border: Color(0xFF2A4060),
    userBubble: Color(0xFF1E3A52),
    iconWell: Color(0xFF1E2D42),
    isDark: true,
  );

  static ChatUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = AppColors.primary;
  static const Color accentDeep = AppColors.accentDeep;
  static const Color accentGold = AppColors.gold;
  static const Color online = AppColors.online;

  static const double radiusCard = 24;
  static const double radiusHero = 28;
  static const double radiusBtn = 28;
  static const double radiusPill = 32;

  static const String pageBackgroundAsset =
      'assets/branding/chat_background.png';
  static const String pageBackgroundAssetDark =
      'assets/branding/chat_background_dark.png';

  static String pageBackgroundAssetFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? pageBackgroundAssetDark
          : pageBackgroundAsset;

  List<BoxShadow> get softShadow => isDark ? const [] : AppColors.light.softShadow(false);

  List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: AppColors.accentGlow,
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}
