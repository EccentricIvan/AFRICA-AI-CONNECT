import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'community_ui.dart';

/// One card shape reused for every "row of info + trailing action" list
/// item in Community (a group in Discover, a conversation in My
/// Community) — white surface, soft shadow, no border, matching
/// `MarketListingCard`.
class CommunityGroupCard extends StatelessWidget {
  const CommunityGroupCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final Widget leading;
  final String title;
  final Widget subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: CommunityUi.radiusCard,
      onTap: onTap ?? () {},
      child: Container(
        margin: EdgeInsets.only(bottom: dense ? 8 : 12),
        padding: EdgeInsets.all(dense ? 12 : 14),
        decoration: BoxDecoration(
          color: CommunityUi.card,
          borderRadius: BorderRadius.circular(CommunityUi.radiusCard),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CommunityUi.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  subtitle,
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// A group/person avatar circle — a gradient wash with an initial,
/// standing in for a real profile photo (none exist yet).
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.color,
    required this.initial,
    this.size = 46,
  });

  final Color color;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.15)!,
            Color.lerp(color, Colors.black, 0.1)!,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
