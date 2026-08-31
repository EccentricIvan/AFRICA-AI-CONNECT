import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    surface: Color(0xFFF3F9FD),
    pageBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF142840),
    textSecondary: Color(0xFF3D5A73),
    border: Color(0xFFE8F2FA),
    isDark: false,
  );

  static const HomeUi darkTheme = HomeUi._(
    card: Color(0xFF1A2433),
    surface: Color(0xFF1E2D42),
    pageBg: Color(0xFF101820),
    textPrimary: Color(0xFFE8F2FC),
    textSecondary: Color(0xFF9BB8D4),
    border: Color(0xFF2A4060),
    isDark: true,
  );

  static HomeUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = AppColors.primary;
  static const Color accentDeep = AppColors.accentDeep;
  static const Color dark = AppColors.surfaceDark;
  static const Color success = AppColors.online;

  static const Color learn = AppColors.learnColor;
  static const Color earn = AppColors.earnColor;
  static const Color grow = AppColors.growColor;
  static const Color thrive = AppColors.thriveColor;

  static const Color askAi = AppColors.chatColor;
  static const Color findJobs = AppColors.jobsColor;
  static const Color learnAction = AppColors.learnColor;
  static const Color marketplaceAction = AppColors.communityColor;

  static const double radiusHero = 32;
  static const double radiusCard = 24;
  static const double radiusBtn = 20;
  static const double radiusChip = 18;
  static const double radiusNav = 32;
  static const double radiusPill = 16;

  static const String heroBackgroundAsset =
      'assets/branding/card_background_light.png';
  static const String heroBackgroundAssetDark =
      'assets/branding/card_background_dark.png';

  static String heroBackgroundAssetFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? heroBackgroundAssetDark
          : heroBackgroundAsset;

  List<BoxShadow> get softShadow => isDark ? const [] : AppColors.light.softShadow(false);
  List<BoxShadow> get navShadow => isDark ? const [] : AppColors.light.navShadow(false);
}
