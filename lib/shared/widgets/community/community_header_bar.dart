import 'package:flutter/material.dart';
import 'community_ui.dart';

/// Back-title header for the Community root screen — matching
/// Marketplace's own header, which also carries a back button (to
/// Home) even though it's a shell tab, not a pushed page. Search lives
/// only inline on each tab now — one search field per context, not a
/// second, separate one up here.
class CommunityHeaderBar extends StatelessWidget {
  const CommunityHeaderBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GlassCircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: CommunityUi.of(context).textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Back button + search field header for Community's pushed sub-pages
/// (Discover full list, My Community full list, chatroom, group detail).
class CommunitySubPageHeaderBar extends StatelessWidget {
  const CommunitySubPageHeaderBar({
    super.key,
    required this.onBack,
    this.title,
    this.searchField,
  });

  final VoidCallback onBack;
  final String? title;
  final Widget? searchField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GlassCircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CommunityUi.of(context).textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else if (searchField != null)
            Expanded(child: searchField!),
        ],
      ),
    );
  }
}

/// The one floating white circle, soft-shadowed icon button used for
/// every header action across Community — matches MarketHeaderBar's
/// glass-circle language instead of a colored tint.
class GlassCircleBtn extends StatelessWidget {
  const GlassCircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ui.card,
            shape: BoxShape.circle,
            boxShadow: ui.softShadow,
          ),
          child: Icon(
            icon,
            size: 22,
            color: filled ? CommunityUi.accent : ui.textPrimary,
          ),
        ),
      ),
    );
  }
}
