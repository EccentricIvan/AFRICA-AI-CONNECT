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

  String get _displayText {
    if (isUser) return text;
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.94;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(maxWidth: maxW),
          decoration: BoxDecoration(
            color: ui.userBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(color: ChatUi.accent.withValues(alpha: 0.18)),
          ),
          child: Text(
            _displayText,
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
                  color: ui.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: ui.softShadow,
                  border: Border.all(color: ui.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOffline) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt_outlined,
                            size: 13,
                            color: ui.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            offlineLabel ?? 'Offline guidance',
                            style: TextStyle(
                              fontSize: 10,
                              color: ui.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      _displayText,
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
