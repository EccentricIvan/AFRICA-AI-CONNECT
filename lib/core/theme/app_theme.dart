import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // Saira carries headings — a distinctive geometric display voice.
  // PlusJakartaSans carries body copy — optimized for legibility on
  // cheap, dim, low-DPI screens at small sizes.
  static const _headingFont = 'Saira';
  static const _bodyFont = 'PlusJakartaSans';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.light.surface,
        onSurface: AppColors.light.textPrimary,
        onSurfaceVariant: AppColors.light.textSecondary,
        outline: AppColors.light.border,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      hintColor: AppColors.light.textHint,
      dividerColor: AppColors.light.border,
    );

    final textTheme = base.textTheme.apply(
      fontFamily: _bodyFont,
      bodyColor: AppColors.light.textPrimary,
      displayColor: AppColors.light.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: TextStyle(
          fontFamily: _headingFont, fontSize: 32, fontWeight: FontWeight.w700,
          color: AppColors.light.textPrimary, height: 1.15, letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: _headingFont, fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.light.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: _headingFont, fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.light.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: _headingFont, fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.light.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: _headingFont, fontSize: 15, fontWeight: FontWeight.w500,
          color: AppColors.light.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: _bodyFont, fontSize: 16, color: AppColors.light.textSecondary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: _bodyFont, fontSize: 14, color: AppColors.light.textSecondary, height: 1.5,
        ),
        labelLarge: TextStyle(
          fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.light.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _headingFont, fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.light.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.light.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.light.surface,
        elevation: 0,
        shadowColor: const Color(0x1A3A2E29),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.light.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.light.textPrimary,
          side: BorderSide(color: AppColors.light.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: TextStyle(
            fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.light.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        hintStyle: TextStyle(fontFamily: _bodyFont, color: AppColors.light.textHint, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.light.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.accent, size: 24);
          }
          return IconThemeData(color: AppColors.light.textHint, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: _bodyFont, fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.accent,
            );
          }
          return TextStyle(fontFamily: _bodyFont, fontSize: 11, color: AppColors.light.textHint);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.light.border, thickness: 1, space: 1,
      ),
    );
  }

  static ThemeData get dark {
    const surfaceDark = Color(0xFF1A1A1A);
    const cardDark = Color(0xFF232323);
    const borderDark = Color(0xFF322F2C);
    const textPrimaryDark = Color(0xFFF2F0EE);
    const textSecondaryDark = Color(0xFFB8B2AC);
    const textHintDark = Color(0xFF8A8480);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        onSurfaceVariant: textSecondaryDark,
        outline: borderDark,
      ),
      scaffoldBackgroundColor: surfaceDark,
      hintColor: textHintDark,
      dividerColor: borderDark,
    );

    final textTheme = base.textTheme.apply(
      fontFamily: _bodyFont,
      bodyColor: textPrimaryDark,
      displayColor: textPrimaryDark,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: const TextStyle(
          fontFamily: _headingFont,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.15,
          letterSpacing: -0.5,
        ),
        headlineLarge: const TextStyle(
          fontFamily: _headingFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontFamily: _headingFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: _headingFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontFamily: _headingFont,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 16,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        bodyMedium: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _headingFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryDark,
          side: const BorderSide(color: borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: _bodyFont,
          color: AppColors.textHint,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 24);
          }
          return const IconThemeData(color: textHintDark, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            );
          }
          return const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 11,
            color: AppColors.textHint,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
