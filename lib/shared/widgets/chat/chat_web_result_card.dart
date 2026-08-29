import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_assistant_avatar.dart';
import 'chat_ui.dart';

/// Shown only when neither the curated knowledge base nor the SALT corpus
/// matched, and only when a live web lookup returned something. Visually
/// distinct from [ChatMessageBubble] on purpose — this text was not
/// authored or reviewed for this app, so it must never look like a normal
/// vetted reply. See WebLookupService for what "unverified" covers.
class ChatWebResultCard extends StatelessWidget {
  const ChatWebResultCard({
    super.key,
    required this.snippet,
    required this.sourceName,
    required this.sourceUrl,
    required this.label,
  });

  final String snippet;
  final String sourceName;
  final String sourceUrl;

  /// Localized "From the web — unverified" header text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.82;
    final ui = ChatUi.of(context);

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
              child: ChatAssistantAvatar(size: 32),
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
                  border: Border.all(color: ChatUi.accentGold.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.public,
                          size: 13,
                          color: ChatUi.accentGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: ChatUi.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snippet,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () =>
                          launchUrl(Uri.parse(sourceUrl)),
                      child: Text(
                        sourceName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ChatUi.accent,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
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
