import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'chat_ui.dart';

class ChatTopicChip extends StatelessWidget {
  const ChatTopicChip({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = ChatUi.of(context);
    return TapScale(
      borderRadius: 18,
      onTap: onTap,
      child: Container(
        width: 86,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: ui.softShadow,
          border: Border.all(color: ui.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ui.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
