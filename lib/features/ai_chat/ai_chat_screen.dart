import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/gemini_service.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = GeminiService();
  bool _isLoading = false;
  late List<_ChatMessage> _messages;
  bool _initialized = false;

  String _t(String key) => S.tr(context, ref, key);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _messages = [_ChatMessage(_t('ai_greeting'), false)];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final locale = ref.read(localeProvider);
    final response = await _chatService.sendMessage(text, locale);

    setState(() {
      _messages.add(_ChatMessage(response, false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _clearChat() {
    _chatService.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(_t('chat_cleared'), false));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ChatAppBar(onClear: _clearChat, t: _t),
              _SuggestedTopics(onTap: (topic) {
                _controller.text = topic;
                _send();
              }, t: _t),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  reverse: true,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == 0) {
                      return _TypingIndicator(t: _t);
                    }
                    final msgIndex = _isLoading ? index - 1 : index;
                    final msg = _messages[_messages.length - 1 - msgIndex];
                    return _MessageBubble(message: msg);
                  },
                ),
              ),
              _ChatInput(
                controller: _controller,
                onSend: _send,
                isLoading: _isLoading,
                t: _t,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({required this.onClear, required this.t});
  final VoidCallback onClear;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.chatColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.chatColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppColors.chatColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  t('powered_by_groq'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x223A2E29),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(t('new_chat'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedTopics extends StatelessWidget {
  const _SuggestedTopics({required this.onTap, required this.t});
  final void Function(String) onTap;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final topics = [
      t('topic_business_q'),
      t('topic_savings_q'),
      t('topic_farming_q'),
      t('topic_sell_online_q'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => onTap(topics[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x223A2E29),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x223A2E29)),
              ),
              child: Text(
                topics[i],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x223A2E29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x183A2E29)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t('thinking'),
              style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : const Color(0x223A2E29),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0x183A2E29)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.onSend, required this.isLoading, required this.t});
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0x223A2E29))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x223A2E29),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: t('ask_anything'),
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isLoading ? const Color(0x223A2E29) : AppColors.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isLoading ? null : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: isLoading ? const Color(0x443A2E29) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage(this.text, this.isUser);
  final String text;
  final bool isUser;
}
