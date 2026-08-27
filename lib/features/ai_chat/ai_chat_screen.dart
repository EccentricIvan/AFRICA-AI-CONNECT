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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _groq = GeminiService();
  final _offlineChat = OfflineChatService();
  bool _isLoading = false;
  late List<_ChatMessage> _messages;
  bool _initialized = false;

  String _t(String key) => S.tr(context, ref, key);

  bool get _isLanding => !_messages.any((m) => m.isUser);

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

  void _sendPrompt(String text) {
    _controller.text = text;
    _send();
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
    var hasNetwork = false;
    try {
      final connectivity = await Connectivity().checkConnectivity();
      hasNetwork = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (_) {
      // If the platform cannot report connectivity, use the bundled knowledge
      // base instead of leaving the chat request in a loading state.
    }

    String response;
    var isOffline = false;

    if (hasNetwork) {
      response = await _groq.sendMessage(text, locale);
      final connectionFailed = response.startsWith(
        'I\'m having trouble connecting',
      );
      if (connectionFailed) {
        final offlineMatch = await _offlineChat.findMatch(text, locale);
        response = offlineMatch?.reply ??
            await _offlineChat.getFallback(locale) ??
            response;
        isOffline = true;
      }
    } else {
      final offlineMatch = await _offlineChat.findMatch(text, locale);
      response = offlineMatch?.reply ??
          await _offlineChat.getFallback(locale) ??
          'No offline answer is available for that question.';
      isOffline = true;
    }
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          response,
          false,
          isOffline: isOffline,
          offlineLabel: isOffline ? S.literal('Offline guidance') : null,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _clearChat() {
    _groq.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(_t('chat_cleared'), false));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);

    final suggestions = [
      (Icons.lightbulb_outline_rounded, _t('topic_business_q')),
      (Icons.account_balance_wallet_outlined, _t('topic_savings_q')),
      (Icons.grass_outlined, _t('topic_farming_q')),
      (Icons.storefront_outlined, _t('topic_sell_online_q')),
    ];

    final popularTopics = [
      (
        Icons.work_outline_rounded,
        S.literal('Business\nAdvice'),
        const Color(0xFFF28C28),
        _t('topic_business_q'),
      ),
      (
        Icons.eco_outlined,
        S.literal('Farming\nTips'),
        const Color(0xFF4D8B55),
        _t('topic_farming_q'),
      ),
      (
        Icons.favorite_border_rounded,
        S.literal('Health\nInfo'),
        const Color(0xFF4A6FA5),
        S.literal('Health tips for my family'),
      ),
      (
        Icons.bar_chart_rounded,
        S.literal('Finance\nGuidance'),
        const Color(0xFFE07818),
        _t('topic_savings_q'),
      ),
      (
        Icons.more_horiz_rounded,
        S.literal('More\nTopics'),
        const Color(0xFF7C5CBF),
        _t('topic_sell_online_q'),
      ),
    ];

    final welcomeBody = _messages.isNotEmpty && !_messages.first.isUser
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
              ChatHeaderBar(
                title: _t('chat_assistant_title'),
                subtitle: _t('app_powered_by'),
                newChatLabel: _t('new_chat'),
                onNewChat: _clearChat,
              ),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = suggestions[i];
                    return ChatSuggestionCard(
                      icon: s.$1,
                      text: s.$2,
                      onTap: () => _sendPrompt(s.$2),
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
                            title: S.literal("Hello, I'm your AI Assistant"),
                            body: welcomeBody,
                          ),
                          const SizedBox(height: 28),
                          Text(
                            S.literal('Explore popular topics'),
                            style: TextStyle(
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
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

class _ChatMessage {
  const _ChatMessage(
    this.text,
    this.isUser, {
    this.isOffline = false,
    this.offlineLabel,
  });
  final String text;
  final bool isUser;
  final bool isOffline;
  final String? offlineLabel;
}
