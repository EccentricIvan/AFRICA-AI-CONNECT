import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'learn_ui.dart';

class LearnToolChip extends StatelessWidget {
  const LearnToolChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return TapScale(
      borderRadius: LearnUi.radiusChip,
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(LearnUi.radiusChip),
          border: Border.all(color: ui.border),
          boxShadow: ui.softShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ui.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ui.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
