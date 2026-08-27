import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'home_ui.dart';

class HomeServiceChip extends StatelessWidget {
  const HomeServiceChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return TapScale(
      onTap: onTap,
      borderRadius: HomeUi.radiusPill,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(HomeUi.radiusPill),
          border: Border.all(color: ui.border),
          boxShadow: ui.softShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ui.textPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ui.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
