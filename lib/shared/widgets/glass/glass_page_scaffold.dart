import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Standard Crystal Sky page canvas — aurora gradient + optional bg asset.
class GlassPageScaffold extends StatelessWidget {
  const GlassPageScaffold({
    super.key,
    required this.body,
    this.backgroundAsset,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final String? backgroundAsset;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.pageDecoration(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundAsset != null)
            Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.35,
              child: Image.asset(
                backgroundAsset!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            body: body,
          ),
        ],
      ),
    );
  }
}
