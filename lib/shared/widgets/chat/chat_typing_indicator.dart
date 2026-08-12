import 'package:flutter/material.dart';
import 'chat_assistant_avatar.dart';
import 'chat_ui.dart';

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key, required this.label});

  final String label;

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChatAssistantAvatar(size: 32, showOnline: false),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ChatUi.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: ChatUi.softShadow,
                border: Border.all(color: ChatUi.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ChatUi.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Row(
                        children: List.generate(3, (i) {
                          final t = (_controller.value + i * 0.2) % 1.0;
                          final scale = 0.55 + 0.45 * (1 - (t - 0.5).abs() * 2);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Transform.scale(
                              scale: scale.clamp(0.55, 1.0),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: ChatUi.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
