import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'home_ui.dart';

class HomeQuickActionCard extends StatelessWidget {
  const HomeQuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return TapScale(
      onTap: onTap,
      borderRadius: 99,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ui.card,
              shape: BoxShape.circle,
              boxShadow: ui.softShadow,
              border: Border.all(color: ui.border),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ui.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
