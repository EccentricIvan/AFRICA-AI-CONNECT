import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderColor,
    this.borderRadius = 20,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final decoration = BoxDecoration(
      gradient: gradient ?? LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.darkTheme.surface.withValues(alpha: 0.8),
                AppColors.darkTheme.surface.withValues(alpha: 0.6),
              ]
            : [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.7),
              ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? AppColors.darkTheme.border.withValues(alpha: 0.3)
                : AppColors.light.border.withValues(alpha: 0.6)),
        width: 1,
      ),
    );

    final container = Container(
      decoration: decoration,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
    return container;
  }
}

class GradientGlassCard extends StatelessWidget {
  const GradientGlassCard({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 20,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withValues(alpha: 0.2),
        width: 1,
      ),
    );

    final container = Container(
      decoration: decoration,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
    return container;
  }
}
