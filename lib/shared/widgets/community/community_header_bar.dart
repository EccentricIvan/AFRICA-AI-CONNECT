import 'package:flutter/material.dart';
import '../glass/glass_circle_btn.dart';
import 'community_ui.dart';

/// Back-title header for the Community root screen.
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

/// Back button + search field header for Community sub-pages.
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
