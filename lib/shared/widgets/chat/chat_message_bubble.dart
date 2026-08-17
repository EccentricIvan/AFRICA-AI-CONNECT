import 'package:flutter/material.dart';
import 'chat_assistant_avatar.dart';
import 'chat_ui.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isOffline = false,
    this.offlineLabel,
  });

  final String text;
  final bool isUser;
  final bool isOffline;
  final String? offlineLabel;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.82;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            color: ChatUi.userBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(color: ChatUi.accent.withValues(alpha: 0.18)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: ChatUi.textPrimary,
              fontSize: 14.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: maxW),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: ChatAssistantAvatar(size: 32, showOnline: false),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: ChatUi.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: ChatUi.softShadow,
                  border: Border.all(color: ChatUi.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOffline) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.offline_bolt_outlined,
                            size: 13,
                            color: ChatUi.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offlineLabel ?? 'Offline guidance',
                            style: const TextStyle(
                              fontSize: 10,
                              color: ChatUi.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        color: ChatUi.textPrimary,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
