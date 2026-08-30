import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'glass/glass_surface.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderColor,
    this.borderRadius = 20,
    this.padding,
    this.onTap,
    this.strong = false,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? AppColors.of(context).border,
          ),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    return GlassSurface(
      borderRadius: borderRadius,
      padding: padding ?? const EdgeInsets.all(16),
      onTap: onTap,
      strong: strong,
      child: child,
    );
  }
}
