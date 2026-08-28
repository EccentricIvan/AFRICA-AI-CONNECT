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
      gradient:
          gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.surfaceDark.withValues(alpha: 0.8),
                      AppColors.surfaceDark.withValues(alpha: 0.6),
                    ]
                    : [
                      AppColors.surface.withValues(alpha: 0.95),
                      AppColors.surface.withValues(alpha: 0.8),
                    ],
          ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      boxShadow:
          isDark
              ? null
              : [
                const BoxShadow(
                  color: Color(0x143A2E29),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
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
