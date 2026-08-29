import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../db/providers/database_provider.dart';
import '../../services/web_lookup_service.dart';
import '../../shared/widgets/chat/chat_composer.dart';
import '../../shared/widgets/chat/chat_header_bar.dart';
import '../../shared/widgets/chat/chat_message_bubble.dart';
import '../../shared/widgets/chat/chat_suggestion_card.dart';
import '../../shared/widgets/chat/chat_topic_chip.dart';
import '../../shared/widgets/chat/chat_typing_indicator.dart';
import '../../shared/widgets/chat/chat_ui.dart';
import '../../shared/widgets/chat/chat_welcome_card.dart';
import '../../shared/widgets/chat/chat_web_result_card.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  String _t(String key) => S.tr(context, ref, key);

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

    final locale = ref.read(localeProvider);
    final historyDao = ref.read(chatHistoryDaoProvider);
    final sessionId = await ref.read(activeChatSessionProvider.future);
    final priorCategory = await historyDao.mostRecentAssistantCategory(
      sessionId,
    );

    await historyDao.addMessage(
      sessionId: sessionId,
      isUser: true,
      content: text,
    );
    _controller.clear();
    if (!mounted) return;
    setState(() => _isLoading = true);
    _scrollToBottom();

    final match = await ref
        .read(offlineChatServiceProvider)
        .findMatch(text, locale, priorCategory: priorCategory);

    String content;
    String? matchedIntentKey;
    String? matchedCategory;
    String? webSourceName;
    String? webSourceUrl;

    if (match != null) {
      content = match.reply;
      matchedIntentKey = match.intentId;
      matchedCategory = match.category;
    } else {
      final webResult = await _tryWebLookup(text, locale);
      if (webResult != null) {
        content = webResult.snippet;
        webSourceName = webResult.sourceName;
        webSourceUrl = webResult.sourceUrl;
      } else {
        content =
            await ref.read(offlineChatServiceProvider).getFallback(locale) ??
            'No offline answer is available for that question.';
      }
    }

    await historyDao.addMessage(
      sessionId: sessionId,
      isUser: false,
      content: content,
      matchedIntentKey: matchedIntentKey,
      matchedCategory: matchedCategory,
      webSourceName: webSourceName,
      webSourceUrl: webSourceUrl,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  /// A fast local check (no network round-trip) gates the web lookup so it
  /// skips straight past several HTTP timeouts when there's clearly no
  /// network, rather than making the user wait it out for nothing.
  Future<WebLookupResult?> _tryWebLookup(String text, AppLocale locale) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasNetwork) return null;
    } catch (_) {
      return null;
    }
    return ref.read(webLookupServiceProvider).lookup(text, locale);
  }

  Future<void> _clearChat() async {
    await ref.read(chatHistoryDaoProvider).startNewSession();
    ref.invalidate(activeChatSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final messages = ref.watch(currentChatMessagesProvider).valueOrNull ?? const [];
    final isLanding = !messages.any((m) => m.isUser);

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
                    if (isLanding)
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        children: [
                          ChatWelcomeCard(
                            title: S.literal("Hello, I'm your AI Assistant"),
                            body: _t('ai_greeting'),
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
                        itemCount: messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoading && index == 0) {
                            return ChatTypingIndicator(label: _t('thinking'));
                          }
                          final msgIndex = _isLoading ? index - 1 : index;
                          final msg = messages[messages.length - 1 - msgIndex];
                          if (!msg.isUser && msg.webSourceUrl != null) {
                            return ChatWebResultCard(
                              snippet: msg.content,
                              sourceName: msg.webSourceName ?? '',
                              sourceUrl: msg.webSourceUrl!,
                              label: _t('from_the_web_unverified'),
                            );
                          }
                          return ChatMessageBubble(
                            text: msg.content,
                            isUser: msg.isUser,
                          );
                        },
                      ),
                    if (isLanding && _isLoading)
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
