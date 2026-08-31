import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CommunityUi {
  const CommunityUi._({
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

  static const CommunityUi light = CommunityUi._(
    pageBg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF142840),
    textSecondary: Color(0xFF3D5A73),
    border: Color(0xFFE8F2FA),
    iconWell: Color(0xFFF3F9FD),
    isDark: false,
  );

  static const CommunityUi darkTheme = CommunityUi._(
    pageBg: Color(0xFF101820),
    card: Color(0xFF1A2433),
    textPrimary: Color(0xFFE8F2FC),
    textSecondary: Color(0xFF9BB8D4),
    border: Color(0xFF2A4060),
    iconWell: Color(0xFF1E2D42),
    isDark: true,
  );

  static CommunityUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = AppColors.primary;
  static const Color accentDeep = AppColors.accentDeep;
  static const Color unread = AppColors.primary;

  static const double radiusHero = 34;
  static const double radiusCard = 28;
  static const double radiusBtn = 28;
  static const double radiusChip = 16;

  static const String heroBackgroundAsset =
      'assets/branding/community_background.png';
  static const String heroBackgroundAssetDark =
      'assets/branding/community_background_dark.png';

  static String heroBackgroundAssetFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? heroBackgroundAssetDark
          : heroBackgroundAsset;

  List<BoxShadow> get softShadow => isDark ? const [] : AppColors.light.softShadow(false);

  List<BoxShadow> get pillShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ];
}
