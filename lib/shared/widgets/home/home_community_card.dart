import 'package:flutter/material.dart';
import 'home_ui.dart';

class HomeCommunityCard extends StatelessWidget {
  const HomeCommunityCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return Material(
      color: ui.card,
      borderRadius: BorderRadius.circular(HomeUi.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(HomeUi.radiusCard),
            border: Border.all(color: ui.border),
            boxShadow: ui.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HomeUi.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: HomeUi.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ui.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: ui.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ui.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
