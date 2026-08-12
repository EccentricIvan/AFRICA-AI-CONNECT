import 'package:flutter/material.dart';
import 'chat_assistant_avatar.dart';
import 'chat_ui.dart';

class ChatHeaderBar extends StatelessWidget {
  const ChatHeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.newChatLabel,
    required this.onNewChat,
  });

  final String title;
  final String subtitle;
  final String newChatLabel;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          const ChatAssistantAvatar(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ChatUi.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ChatUi.textSecondary,
                      height: 1.25,
                    ),
                    children: _subtitleSpans(subtitle),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNewChat,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ChatUi.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ChatUi.border),
                  boxShadow: ChatUi.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: ChatUi.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      newChatLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: ChatUi.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _subtitleSpans(String raw) {
    const brand = 'Africa AI Connect';
    final idx = raw.indexOf(brand);
    if (idx < 0) {
      return [TextSpan(text: raw)];
    }
    return [
      TextSpan(text: raw.substring(0, idx)),
      const TextSpan(
        text: brand,
        style: TextStyle(
          color: ChatUi.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      TextSpan(text: raw.substring(idx + brand.length)),
    ];
  }
}
