import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Frosted glass container — blur + translucent fill + luminous border.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.onTap,
    this.strong = false,
    this.blurSigma,
    this.solidFallback = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool strong;
  final double? blurSigma;
  final bool solidFallback;

  @override
  Widget build(BuildContext context) {
    final sigma = blurSigma ??
        (strong ? AppColors.glassBlurSigmaHeavy : AppColors.glassBlurSigma);
    final fill = AppColors.glassFill(context, strong: strong);
    final highlight = AppColors.glassBorderHighlight(context);
    final dim = AppColors.glassBorderDim(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border(
          top: BorderSide(color: highlight, width: 1),
          left: BorderSide(color: highlight, width: 1),
          bottom: BorderSide(color: dim, width: 1),
          right: BorderSide(color: dim, width: 1),
        ),
        boxShadow: isDark ? null : AppColors.light.softShadow(false),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: solidFallback
            ? ColoredBox(color: fill, child: _inner())
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: fill),
                  child: _inner(),
                ),
              ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _inner() => Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
}
