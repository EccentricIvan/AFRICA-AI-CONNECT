import 'package:flutter/material.dart';
import 'learn_ui.dart';

class LearnSectionHeader extends StatelessWidget {
  const LearnSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LearnUi.of(context).textPrimary,
              height: 1.2,
            ),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LearnUi.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
