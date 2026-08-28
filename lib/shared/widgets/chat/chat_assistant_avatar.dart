import 'package:flutter/material.dart';
import 'chat_ui.dart';

/// Soft AI mark that sits flush with the page — no separate white plate.
class ChatAssistantAvatar extends StatelessWidget {
  const ChatAssistantAvatar({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    final iconSize = size * 0.46;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ChatUi.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.auto_awesome, size: iconSize, color: ChatUi.accent),
    );
  }
}
