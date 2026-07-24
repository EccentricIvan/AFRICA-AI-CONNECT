import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../core/l10n/app_strings.dart';
import 'api_config.dart';
import 'offline_language_service.dart';

class ChatReply {
  const ChatReply({
    required this.answer,
    required this.suggestedQuestions,
    required this.usedOffline,
  });

  final String answer;
  final List<String> suggestedQuestions;
  final bool usedOffline;
}

String getAiLanguageInstruction(AppLocale locale) {
  switch (locale) {
    case AppLocale.lg:
      return '''
The user selected Luganda / Oluganda.
Selected language code: lg.
You must always reply in clear, natural Luganda.
Do not switch to English unless the user explicitly asks.
If a technical word has no natural Luganda translation, keep the technical word in English and explain it simply in Luganda.
Keep the tone warm, practical, and helpful for Ugandan users.
Every answer in this conversation must continue in Luganda.
''';
    case AppLocale.sw:
      return '''
The user selected Kiswahili.
Selected language code: sw.
You must always reply in clear, natural Kiswahili.
Do not switch to English unless the user explicitly asks.
If a technical word has no natural Kiswahili translation, keep the technical word in English and explain it simply in Kiswahili.
Keep the tone warm, practical, and helpful.
Every answer in this conversation must continue in Kiswahili.
''';
    case AppLocale.en:
      return '''
The user selected English.
Selected language code: en.
Reply in clear, natural, simple English.
''';
  }
}

class GeminiService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _maxHistoryMessages = 12;
  static const _contextHistoryMessages = 8;

  static const _systemPrompt =
      '''You are the Africa AI Connect Assistant, a warm, supportive, and knowledgeable companion for women in Sub-Saharan Africa.

Your role is to help women with:
- Business and entrepreneurship advice
- Agricultural tips and farming guidance
- Financial literacy: savings, budgeting, mobile money, and SACCOs
- Health and nutrition information
- Digital skills guidance
- Job and career advice
- Community building and leadership

Guidelines:
- Be warm, encouraging, and practical.
- Give thoughtful, actionable advice with enough detail to be genuinely useful.
- Use simple language accessible to all literacy levels.
- Be culturally sensitive to East African context.
- When discussing health topics, recommend consulting a healthcare professional for serious concerns.
- Preserve conversation flow and treat short follow-up questions as connected to the recent topic.
- Use human-reviewed dataset context as grounding when provided, but do not copy dataset answers directly.
- Connect related dataset ideas into a fresh answer that fits the user's actual question.
- Suggest 2 or 3 helpful follow-up questions related to the user's current topic.
- Keep responses focused unless asked for detail.''';

  final List<Map<String, String>> _history = [];
  String? _historyLanguageCode;
  String? _lastMatchedEntryId;
  String? _lastMatchedCategory;
  List<String> _lastMatchedContentIds = const [];
  String? _currentTopic;
  String? _lastUserQuestion;
  String? _lastAssistantAnswer;

  Future<ChatReply> sendMessage(
    String message,
    AppLocale selectedLocale,
  ) async {
    final languageService = OfflineLanguageService.instance;
    if (languageService.currentLanguageCode != selectedLocale.name) {
      await languageService.loadLanguage(selectedLocale.name);
    }

    final effectiveLocale = AppLocale.fromLanguageCode(
      languageService.currentLanguageCode,
    );
    final selectedLanguageCode = effectiveLocale.name;
    if (_historyLanguageCode != selectedLanguageCode) {
      clearHistory();
      _historyLanguageCode = selectedLanguageCode;
    }

    _lastUserQuestion = message;
    _history.add({'role': 'user', 'content': message});
    _trimHistory();

    if (!ApiConfig.hasOnlineAiConfig || await _isOffline()) {
      return _offlineReplyFor(message);
    }

    final contextMessages = _topicContextMessages(excludeLast: true);
    final referenceContext = languageService.buildGroqContext(
      message,
      contextMessages: contextMessages,
    );
    final messages = [
      {'role': 'system', 'content': getAiLanguageInstruction(effectiveLocale)},
      {'role': 'system', 'content': _systemPrompt},
      {
        'role': 'system',
        'content':
            'Return valid JSON only with this exact shape: '
            '{"answer":"...","suggestedQuestions":["...","..."]}. '
            'The answer and suggestedQuestions must be in the selected '
            'language ($selectedLanguageCode). Include 2 or 3 suggestions. '
            'Use the recent conversation history to understand follow-up '
            'questions. If the provided reference context is relevant, reason '
            'from it, connect related ideas, give practical examples, and do '
            'not copy stored answers directly or contradict the context.',
      },
      if (_currentTopic != null && _currentTopic!.trim().isNotEmpty)
        {
          'role': 'system',
          'content': 'Current topic from recent conversation: $_currentTopic',
        },
      if (referenceContext.isNotEmpty)
        {'role': 'system', 'content': referenceContext},
      ..._history,
    ];

    if (ApiConfig.hasGroqKey) {
      final reply = await _sendDirectGroqReply(
        messages,
        languageService,
        message,
        contextMessages,
      );
      if (reply != null) return reply;
    }

    if (ApiConfig.hasChatBackend) {
      final reply = await _sendBackendReply(
        message,
        effectiveLocale,
        languageService,
        contextMessages,
        referenceContext,
      );
      if (reply != null) return reply;
    }

    return _offlineReplyFor(message);
  }

  void clearHistory() {
    _history.clear();
    _lastMatchedEntryId = null;
    _lastMatchedCategory = null;
    _lastMatchedContentIds = const [];
    _currentTopic = null;
    _lastUserQuestion = null;
    _lastAssistantAnswer = null;
  }

  Future<bool> _isOffline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return false;
      return results.every((result) => result == ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  ChatReply _offlineReplyFor(String message) {
    final languageService = OfflineLanguageService.instance;
    final contextMessages = _topicContextMessages(excludeLast: true);
    final offlineResult = languageService.getOfflineChatResult(
      message,
      contextMessages: contextMessages,
      previousEntryId: _lastMatchedEntryId,
      previousCategory: _lastMatchedCategory,
    );
    _updateTopicFromOfflineResult(offlineResult);

    _lastAssistantAnswer = offlineResult.answer;
    _history.add({'role': 'assistant', 'content': offlineResult.answer});
    _trimHistory();
    return ChatReply(
      answer: offlineResult.answer,
      suggestedQuestions: offlineResult.suggestedQuestions,
      usedOffline: true,
    );
  }

  Future<ChatReply?> _sendDirectGroqReply(
    List<Map<String, String>> messages,
    OfflineLanguageService languageService,
    String message,
    Iterable<String> contextMessages,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConfig.groqKey}',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.65,
              'max_tokens': 900,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final rawText =
          data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';

      if (rawText.isEmpty) return null;

      return _completeOnlineReply(
        rawText,
        languageService,
        message,
        contextMessages,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ChatReply?> _sendBackendReply(
    String message,
    AppLocale effectiveLocale,
    OfflineLanguageService languageService,
    Iterable<String> contextMessages,
    String referenceContext,
  ) async {
    final endpoint = ApiConfig.chatBackendUri;
    if (endpoint == null) return null;

    try {
      final response = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': _buildBackendMessage(
                message,
                contextMessages,
                referenceContext,
                effectiveLocale,
              ),
              'language': _backendLanguageFor(effectiveLocale),
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final rawText = _firstNonEmptyText([
        data['answer'],
        data['reply'],
        data['response'],
      ]);

      if (rawText.isEmpty) return null;

      return _completeOnlineReply(
        rawText,
        languageService,
        message,
        contextMessages,
      );
    } catch (_) {
      return null;
    }
  }

  ChatReply _completeOnlineReply(
    String rawText,
    OfflineLanguageService languageService,
    String message,
    Iterable<String> contextMessages,
  ) {
    final reply = _parseGroqReply(
      rawText,
      languageService,
      message,
      contextMessages,
    );
    _updateTopicFromSearch(languageService, message, contextMessages);
    _lastAssistantAnswer = reply.answer;
    _history.add({'role': 'assistant', 'content': reply.answer});
    _trimHistory();
    return reply;
  }

  String _buildBackendMessage(
    String message,
    Iterable<String> contextMessages,
    String referenceContext,
    AppLocale effectiveLocale,
  ) {
    final buffer =
        StringBuffer()
          ..writeln('Selected language code: ${effectiveLocale.name}.')
          ..writeln(
            'Answer naturally and helpfully in the selected language. '
            'Use the recent conversation to understand follow-up questions. '
            'Reason from the dataset context if it is relevant, but do not '
            'copy stored answers directly.',
          );

    if (_currentTopic != null && _currentTopic!.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Current topic: $_currentTopic');
    }

    if (contextMessages.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Recent conversation context:');
      for (final context in contextMessages) {
        buffer.writeln('- $context');
      }
    }

    if (referenceContext.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(referenceContext);
    }

    buffer
      ..writeln()
      ..writeln('Current user message:')
      ..writeln(message)
      ..writeln()
      ..writeln(
        'Suggest 2 or 3 useful, topic-specific follow-up questions if '
        'appropriate.',
      );

    return buffer.toString().trim();
  }

  String _backendLanguageFor(AppLocale locale) {
    switch (locale) {
      case AppLocale.lg:
        return 'luganda';
      case AppLocale.sw:
        return 'swahili';
      case AppLocale.en:
        return 'english';
    }
  }

  String _firstNonEmptyText(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  ChatReply _parseGroqReply(
    String rawText,
    OfflineLanguageService languageService,
    String message,
    Iterable<String> contextMessages,
  ) {
    final decoded = _tryDecodeJsonObject(rawText);
    if (decoded != null) {
      final answer = decoded['answer']?.toString().trim() ?? '';
      final suggestions = _readSuggestedQuestions(
        decoded['suggestedQuestions'],
      );
      final supplementedSuggestions = _supplementSuggestions(
        suggestions,
        languageService,
        message,
        answer,
        contextMessages,
      );

      if (answer.isNotEmpty) {
        return ChatReply(
          answer: answer,
          suggestedQuestions: supplementedSuggestions,
          usedOffline: false,
        );
      }
    }

    return ChatReply(
      answer: rawText,
      suggestedQuestions: _supplementSuggestions(
        const [],
        languageService,
        message,
        rawText,
        contextMessages,
      ),
      usedOffline: false,
    );
  }

  Map<String, dynamic>? _tryDecodeJsonObject(String rawText) {
    Object? decoded;
    try {
      decoded = jsonDecode(rawText);
    } catch (_) {
      final start = rawText.indexOf('{');
      final end = rawText.lastIndexOf('}');
      if (start < 0 || end <= start) return null;

      try {
        decoded = jsonDecode(rawText.substring(start, end + 1));
      } catch (_) {
        return null;
      }
    }

    return decoded is Map<String, dynamic> ? decoded : null;
  }

  List<String> _readSuggestedQuestions(Object? value) {
    if (value is! List) return const [];

    return List.unmodifiable(
      value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .take(3),
    );
  }

  List<String> _supplementSuggestions(
    List<String> suggestions,
    OfflineLanguageService languageService,
    String message,
    String answer,
    Iterable<String> contextMessages,
  ) {
    final merged = <String>[];
    final groundedSuggestions = languageService.getOfflineSuggestedQuestions(
      message,
      contextMessages: [
        ...contextMessages,
        if (answer.trim().isNotEmpty) answer,
      ],
      assistantAnswer: answer,
      limit: 3,
    );
    final relevanceContext = [
      message,
      answer,
      if (_currentTopic != null) _currentTopic!,
      ...contextMessages,
      ...groundedSuggestions,
    ].join(' ');

    void addSuggestion(String suggestion) {
      final trimmed = suggestion.trim();
      if (trimmed.isEmpty) return;

      final exists = merged.any(
        (item) => item.toLowerCase().trim() == trimmed.toLowerCase(),
      );
      if (!exists) merged.add(trimmed);
    }

    for (final suggestion in suggestions) {
      if (_isSuggestionRelevant(suggestion, relevanceContext)) {
        addSuggestion(suggestion);
      }
    }

    for (final suggestion in groundedSuggestions) {
      addSuggestion(suggestion);
      if (merged.length >= 3) break;
    }

    return List.unmodifiable(merged.take(3));
  }

  bool _isSuggestionRelevant(String suggestion, String context) {
    final suggestionTerms = _suggestionTerms(suggestion);
    if (suggestionTerms.isEmpty) return false;

    final contextTerms = _suggestionTerms(context);
    if (contextTerms.isEmpty) return true;

    for (final term in suggestionTerms) {
      if (contextTerms.contains(term)) return true;
    }

    return false;
  }

  Set<String> _suggestionTerms(String value) {
    final normalized =
        value
            .toLowerCase()
            .replaceAll(RegExp(r'[_\-/]'), ' ')
            .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
            .replaceAll("'", ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    if (normalized.isEmpty) return const {};

    return normalized
        .split(' ')
        .where(
          (term) => term.length > 2 && !_suggestionStopWords.contains(term),
        )
        .toSet();
  }

  void _updateTopicFromOfflineResult(OfflineChatResult result) {
    if (result.matchedEntryId == null || result.matchedCategory == null) {
      return;
    }

    _lastMatchedEntryId = result.matchedEntryId;
    _lastMatchedCategory = result.matchedCategory;
    _lastMatchedContentIds = result.matchedContentIds;
    _currentTopic = result.matchedCategory;
    if (result.currentTopic != null && result.currentTopic!.trim().isNotEmpty) {
      _currentTopic = '${result.matchedCategory}: ${result.currentTopic}';
    }
  }

  void _updateTopicFromSearch(
    OfflineLanguageService languageService,
    String message,
    Iterable<String> contextMessages,
  ) {
    final matches = languageService.searchContent(
      message,
      contextMessages: contextMessages,
      limit: 5,
    );
    if (matches.isEmpty) return;

    final entry = matches.first;
    _lastMatchedEntryId = entry.id;
    _lastMatchedCategory = entry.category;
    _lastMatchedContentIds = List.unmodifiable(
      matches.map((match) => match.id).take(5),
    );
    _currentTopic = '${entry.category}: ${entry.title}';
  }

  List<String> _topicContextMessages({required bool excludeLast}) {
    final messages = <String>[
      if (_currentTopic != null && _currentTopic!.trim().isNotEmpty)
        'current topic: $_currentTopic',
      if (_lastMatchedContentIds.isNotEmpty)
        'last matched content ids: ${_lastMatchedContentIds.join(', ')}',
      if (_lastUserQuestion != null && _lastUserQuestion!.trim().isNotEmpty)
        'last user question: ${_summarizeForContext(_lastUserQuestion!)}',
      if (_lastAssistantAnswer != null &&
          _lastAssistantAnswer!.trim().isNotEmpty)
        'last assistant answer: ${_summarizeForContext(_lastAssistantAnswer!)}',
      ..._recentContextMessages(excludeLast: excludeLast),
    ];

    return List.unmodifiable(messages);
  }

  List<String> _recentContextMessages({required bool excludeLast}) {
    final end =
        excludeLast && _history.isNotEmpty
            ? _history.length - 1
            : _history.length;
    final start =
        end > _contextHistoryMessages ? end - _contextHistoryMessages : 0;
    final messages = <String>[];

    for (var index = start; index < end; index += 1) {
      final item = _history[index];
      final role = item['role'] ?? 'message';
      final content = item['content'] ?? '';
      if (content.trim().isNotEmpty) {
        messages.add('$role: ${_summarizeForContext(content)}');
      }
    }

    return List.unmodifiable(messages);
  }

  String _summarizeForContext(String content) {
    final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 220) return normalized;
    return '${normalized.substring(0, 220)}...';
  }

  void _trimHistory() {
    while (_history.length > _maxHistoryMessages) {
      _history.removeAt(0);
    }
  }

  static const _suggestionStopWords = {
    'about',
    'and',
    'are',
    'can',
    'could',
    'for',
    'from',
    'how',
    'should',
    'that',
    'the',
    'this',
    'what',
    'when',
    'where',
    'with',
    'you',
    'your',
    'kwa',
    'jinsi',
    'gani',
    'nini',
    'na',
    'ya',
    'za',
    'ku',
    'ni',
    'oba',
    'era',
    'nga',
    'tya',
  };
}
