import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'chat_ui.dart';

class ChatSuggestionCard extends StatelessWidget {
  const ChatSuggestionCard({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = ChatUi.of(context);
    return TapScale(
      borderRadius: ChatUi.radiusCard,
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(ChatUi.radiusCard),
          boxShadow: ui.softShadow,
          border: Border.all(color: ui.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ui.iconWell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: ChatUi.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ui.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ui.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
