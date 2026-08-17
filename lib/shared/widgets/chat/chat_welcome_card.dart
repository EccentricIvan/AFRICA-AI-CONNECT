import 'package:flutter/material.dart';
import 'chat_assistant_avatar.dart';
import 'chat_ui.dart';

class ChatWelcomeCard extends StatelessWidget {
  const ChatWelcomeCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: ChatUi.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(ChatUi.radiusHero),
        boxShadow: ChatUi.softShadow,
        border: Border.all(color: ChatUi.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChatAssistantAvatar(size: 44),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Saira',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ChatUi.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ChatUi.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
