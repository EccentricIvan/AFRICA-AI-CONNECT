import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a lesson diagram (bundled SVG or image, or an online one) with a
/// fallback label.
class CurriculumDiagram extends StatelessWidget {
  const CurriculumDiagram({
    super.key,
    required this.assetPath,
    this.semanticLabel,
  });

  final String assetPath;
  final String? semanticLabel;

  /// SVGs we draw, bundled PNG/JPEG diagrams, or a picture from an online
  /// topic look-up (an http(s) URL), which shows nothing when offline.
  Widget _picture() {
    final label = semanticLabel ?? 'Lesson diagram';
    if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
      // A look-up's lead picture is Wikipedia's original, often 4000+ px
      // wide: decoded at full size, it stalls every frame while the chat
      // scrolls. Decode it once at a size the card can actually show.
      return Image.network(
        assetPath,
        cacheWidth: 1200,
        fit: BoxFit.contain,
        semanticLabel: label,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (!assetPath.toLowerCase().endsWith('.svg')) {
      return Image.asset(assetPath, fit: BoxFit.contain, semanticLabel: label);
    }
    return SvgPicture.asset(
      assetPath,
      fit: BoxFit.contain,
      semanticsLabel: label,
      placeholderBuilder: (_) => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: _picture(),
      ),
    );
  }
}
