import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'glass_surface.dart';

/// Circular icon button — solid white by default; glass blur opt-in only.
class GlassCircleBtn extends StatelessWidget {
  const GlassCircleBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.filled = false,
    this.useGlass = false,
    this.solidFallback = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool filled;
  final bool useGlass;
  final bool solidFallback;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final iconWidget = Icon(
      icon,
      size: iconSize,
      color: filled ? AppColors.primary : ac.textPrimary,
    );

    if (useGlass) {
      return GlassSurface(
        borderRadius: size / 2,
        onTap: onTap,
        solidFallback: solidFallback,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: size,
          height: size,
          child: iconWidget,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ac.surface,
            border: Border.all(color: ac.border),
            boxShadow: ac.softShadow(false),
          ),
          child: iconWidget,
        ),
      ),
    );
  }
}
