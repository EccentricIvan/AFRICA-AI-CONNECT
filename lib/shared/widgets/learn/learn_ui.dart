import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LearnUi {
  const LearnUi._({
    required this.pageBg,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.isDark,
  });

  final Color pageBg;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final bool isDark;

  static const LearnUi light = LearnUi._(
    pageBg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF142840),
    textSecondary: Color(0xFF3D5A73),
    border: Color(0xFFE8F2FA),
    isDark: false,
  );

  static const LearnUi darkTheme = LearnUi._(
    pageBg: Color(0xFF101820),
    card: Color(0xFF1A2433),
    textPrimary: Color(0xFFE8F2FC),
    textSecondary: Color(0xFF9BB8D4),
    border: Color(0xFF2A4060),
    isDark: true,
  );

  static LearnUi of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const Color accent = AppColors.primary;
  static const Color accentDeep = AppColors.accentDeep;
  static const Color success = AppColors.online;

  static const double radiusHero = 32;
  static const double radiusCard = 24;
  static const double radiusBtn = 28;
  static const double radiusChip = 16;

  static const String heroBackgroundAsset =
      'assets/branding/learn_background.png';
  static const String heroBackgroundAssetDark =
      'assets/branding/learn_background_dark.png';

  static const String progressMascotAsset =
      'assets/branding/learn_progress_mascot.png';

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
