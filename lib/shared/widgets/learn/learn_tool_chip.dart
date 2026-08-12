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
    return TapScale(
      borderRadius: LearnUi.radiusChip,
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: LearnUi.card,
          borderRadius: BorderRadius.circular(LearnUi.radiusChip),
          border: Border.all(color: LearnUi.border),
          boxShadow: LearnUi.softShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: LearnUi.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LearnUi.textPrimary,
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
