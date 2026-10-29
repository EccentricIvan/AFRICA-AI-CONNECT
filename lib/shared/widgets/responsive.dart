import 'package:flutter/material.dart';

/// Centers [child] and caps its width so content stays readable on
/// wide desktop windows. Phones are unaffected.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 840});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Picks a column count for grids based on available width.
int adaptiveColumns(double width, {int min = 2, int max = 4, double itemWidth = 220}) {
  final cols = (width / itemWidth).floor();
  return cols.clamp(min, max);
}
