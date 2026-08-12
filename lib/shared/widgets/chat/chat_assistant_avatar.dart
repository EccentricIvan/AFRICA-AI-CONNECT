import 'package:flutter/material.dart';
import 'chat_ui.dart';

/// Soft AI mark that sits flush with the page — no separate white plate.
class ChatAssistantAvatar extends StatelessWidget {
  const ChatAssistantAvatar({
    super.key,
    this.size = 44,
    this.showOnline = true,
  });

  final double size;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final iconSize = size * 0.46;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: ChatUi.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radius),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_awesome,
              size: iconSize,
              color: ChatUi.accent,
            ),
          ),
          if (showOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: ChatUi.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChatUi.pageBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
