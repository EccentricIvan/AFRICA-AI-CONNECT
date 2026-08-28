import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'chat_ui.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.isLoading,
    this.onAttach,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final bool isLoading;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    final ui = ChatUi.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(ChatUi.radiusPill),
          boxShadow: ui.softShadow,
          border: Border.all(color: ui.border),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onAttach,
              icon: Icon(
                Icons.attach_file_rounded,
                color: ui.textSecondary,
                size: 22,
              ),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: ui.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 4),
            TapScale(
              borderRadius: 22,
              onTap: isLoading ? () {} : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isLoading
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [ChatUi.accent, ChatUi.accentDeep],
                        ),
                  color: isLoading ? ui.border : null,
                  boxShadow: isLoading ? null : ui.glowShadow,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: isLoading
                      ? ui.textSecondary.withValues(alpha: 0.5)
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
