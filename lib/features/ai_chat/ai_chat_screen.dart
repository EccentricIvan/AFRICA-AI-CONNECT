import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/gemini_service.dart';
import '../../services/offline_chat_service.dart';
import '../../shared/widgets/chat/chat_composer.dart';
import '../../shared/widgets/chat/chat_header_bar.dart';
import '../../shared/widgets/chat/chat_message_bubble.dart';
import '../../shared/widgets/chat/chat_suggestion_card.dart';
import '../../shared/widgets/chat/chat_topic_chip.dart';
import '../../shared/widgets/chat/chat_typing_indicator.dart';
import '../../shared/widgets/chat/chat_ui.dart';
import '../../shared/widgets/chat/chat_welcome_card.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _minimumThinkingDuration = Duration(milliseconds: 1200);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _groq = GeminiService();
  final _offlineChat = OfflineChatService();
  bool _isLoading = false;
  late List<_ChatMessage> _messages;
  bool _initialized = false;

  String _t(String key) => ref.watch(offlineLanguageServiceProvider).t(key);
  String _chatGreeting() {
    final languageService = ref.read(offlineLanguageServiceProvider);
    final greetings = languageService.getChatResponses('greetings');
    return greetings.isEmpty
        ? languageService.t('ai_greeting')
        : greetings.first;
  }

  bool get _isLanding => !_messages.any((m) => m.isUser);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _messages = [_ChatMessage.assistant(_chatGreeting())];
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

  Future<void> _send([String? suggestedQuestion]) async {
    final text = (suggestedQuestion ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    final thinkingStartedAt = DateTime.now();

    final locale = ref.read(localeProvider);
    final languageService = ref.read(offlineLanguageServiceProvider);

    ChatReply reply;

    try {
      reply = await _groq.sendMessage(text, locale);
    } catch (_) {
      final answer = languageService.getOfflineChatReply(text);
      reply = ChatReply(
        answer: answer,
        suggestedQuestions: languageService.getOfflineSuggestedQuestions(
          text,
          assistantAnswer: answer,
        ),
        usedOffline: true,
      );
    }

    await _waitForThinkingCue(thinkingStartedAt);
    if (!mounted) return;

    String response;
    var isOffline = false;

    if (hasNetwork) {
      response = await _groq.sendMessage(text, locale);
      final connectionFailed = response.startsWith(
        'I\'m having trouble connecting',
      );
      if (connectionFailed) {
        final offlineMatch = await _offlineChat.findMatch(text, locale);
        response =
            offlineMatch?.reply ??
            await _offlineChat.getFallback(locale) ??
            response;
        isOffline = true;
      }
    } else {
      final offlineMatch = await _offlineChat.findMatch(text, locale);
      response =
          offlineMatch?.reply ??
          await _offlineChat.getFallback(locale) ??
          'No offline answer is available for that question.';
      isOffline = true;
    }
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage.assistant(
          reply.answer.trim().isEmpty
              ? languageService.getFallbackResponse()
              : reply.answer,
          suggestedQuestions: reply.suggestedQuestions,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _waitForThinkingCue(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remainingMs =
        _minimumThinkingDuration.inMilliseconds - elapsed.inMilliseconds;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  void _clearChat() {
    _groq.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage.assistant(_chatGreeting()));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    ref.watch(offlineLanguageServiceProvider);
    ref.listen<AppLocale>(localeProvider, (previous, next) {
      if (previous == next || !_initialized) return;
      _groq.clearHistory();
      setState(() {
        _messages
          ..clear()
          ..add(_ChatMessage.assistant(_chatGreeting()));
      });
    });

    final suggestions = [
      (Icons.lightbulb_outline_rounded, _t('topic_business_q')),
      (Icons.account_balance_wallet_outlined, _t('topic_savings_q')),
      (Icons.grass_outlined, _t('topic_farming_q')),
      (Icons.storefront_outlined, _t('topic_sell_online_q')),
    ];

    final popularTopics = [
      (
        Icons.work_outline_rounded,
        _t('marketplace'),
        const Color(0xFFF28C28),
        _t('topic_business_q'),
      ),
      (
        Icons.eco_outlined,
        _t('topic_farming_q'),
        const Color(0xFF4D8B55),
        _t('topic_farming_q'),
      ),
      (
        Icons.favorite_border_rounded,
        _t('health'),
        const Color(0xFF4A6FA5),
        _t('health'),
      ),
      (
        Icons.bar_chart_rounded,
        _t('finance'),
        const Color(0xFFE07818),
        _t('topic_savings_q'),
      ),
      (
        Icons.more_horiz_rounded,
        _t('community'),
        const Color(0xFF7C5CBF),
        _t('topic_sell_online_q'),
      ),
    ];

    final welcomeBody =
        _messages.isNotEmpty && !_messages.first.isUser
            ? _messages.first.text
            : _t('ai_greeting');

    final chatUi = ChatUi.of(context);
    return Scaffold(
      backgroundColor: chatUi.pageBg,
      body: Container(
        decoration: BoxDecoration(
          color: chatUi.pageBg,
          // The branded background photo is a light, cream-toned image —
          // it only stays legible under light-mode's dark text. In dark
          // mode we drop it and just show the solid dark page color, or
          // every title/label sitting directly on the page (not inside an
          // opaque card) would wash out against it, exactly as reported.
          image: chatUi.isDark
              ? null
              : const DecorationImage(
                  image: AssetImage(ChatUi.pageBackgroundAsset),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ChatAppBar(onClear: _clearChat, t: _t),
              _SuggestedTopics(onTap: _send, t: _t),
              Expanded(
                child:
                    _messages.isEmpty && !_isLoading
                        ? _EmptyChatState(t: _t)
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          reverse: true,
                          itemCount: _messages.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isLoading && index == 0) {
                              return _TypingIndicator(t: _t);
                            }
                            final msgIndex = _isLoading ? index - 1 : index;
                            final msg =
                                _messages[_messages.length - 1 - msgIndex];
                            return _MessageBubble(
                              message: msg,
                              onSuggestionTap: _isLoading ? null : _send,
                            );
                          },
                        ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (_isLanding)
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        children: [
                          ChatWelcomeCard(
                            title: _t('chat_assistant_title'),
                            body: welcomeBody,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _t('explore_pillars'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: chatUi.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 108,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: popularTopics.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final topic = popularTopics[i];
                                return ChatTopicChip(
                                  icon: topic.$1,
                                  label: topic.$2,
                                  accent: topic.$3,
                                  onTap: () => _sendPrompt(topic.$4),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        reverse: true,
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoading && index == 0) {
                            return ChatTypingIndicator(label: _t('thinking'));
                          }
                          final msgIndex = _isLoading ? index - 1 : index;
                          final msg =
                              _messages[_messages.length - 1 - msgIndex];
                          return ChatMessageBubble(
                            text: msg.text,
                            isUser: msg.isUser,
                            isOffline: msg.isOffline,
                            offlineLabel: msg.offlineLabel,
                          );
                        },
                      ),
                    if (_isLanding && _isLoading)
                      Positioned(
                        left: 16,
                        bottom: 8,
                        child: ChatTypingIndicator(label: _t('thinking')),
                      ),
                  ],
                ),
              ),
              ChatComposer(
                controller: _controller,
                hint: _t('ask_anything'),
                onSend: _send,
                isLoading: _isLoading,
                onAttach: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t('empty_chat'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            height: 1.4,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.chatColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.chatColor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.chatColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('ai_assistant'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  t('ask_ai_assistant_desc'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
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
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t('new_chat'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t('thinking'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onSuggestionTap});
  final _ChatMessage message;
  final void Function(String question)? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accent : const Color(0x223A2E29),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border:
                    isUser ? null : Border.all(color: const Color(0x183A2E29)),
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
            if (!isUser && message.suggestedQuestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      message.suggestedQuestions.map((question) {
                        return _SuggestionChip(
                          question: question,
                          onTap:
                              onSuggestionTap == null
                                  ? null
                                  : () => onSuggestionTap!(question),
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.question, required this.onTap});

  final String question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chatColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.chatColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          question,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.t,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: t('chat_placeholder'),
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: t('send'),
            child: Semantics(
              button: true,
              label: t('send'),
              child: GestureDetector(
                onTap: isLoading ? null : onSend,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isLoading ? const Color(0x223A2E29) : AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow:
                        isLoading
                            ? null
                            : [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage._(this.text, this.isUser, this.suggestedQuestions);

  factory _ChatMessage.user(String text) {
    return _ChatMessage._(text, true, const []);
  }

  factory _ChatMessage.assistant(
    String text, {
    List<String> suggestedQuestions = const [],
  }) {
    return _ChatMessage._(
      text,
      false,
      List.unmodifiable(suggestedQuestions.take(3)),
    );
  }

  final String text;
  final bool isUser;
  final List<String> suggestedQuestions;
}
