import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../core/l10n/app_strings.dart';

class OfflineChatMatch {
  const OfflineChatMatch({
    required this.reply,
    required this.intentId,
    required this.category,
    required this.score,
    this.sourceTitle,
    this.sourceUrl,
  });

  final String reply;
  final String intentId;
  final String category;
  final int score;
  final String? sourceTitle;
  final String? sourceUrl;
}

class OfflineChatService {
  Map<String, dynamic>? _knowledgeBase;

  Future<void> _loadKnowledgeBase() async {
    if (_knowledgeBase != null) return;

    final decoded = jsonDecode(
      await rootBundle.loadString('assets/offline/offline_chat.json'),
    );
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'The offline chat file must contain a JSON object.',
      );
    }
    _knowledgeBase = decoded;
  }

  String _normalize(String text) =>
      text
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  Set<String> _tokens(String text) =>
      _normalize(text).split(' ').where((token) => token.length > 1).toSet();

  int _score(String message, String candidate) {
    final normalizedCandidate = _normalize(candidate);
    if (normalizedCandidate.isEmpty) return 0;
    if (message == normalizedCandidate) return 1200 + candidate.length;
    if (message.contains(normalizedCandidate) ||
        normalizedCandidate.contains(message)) {
      return 500 + math.min(message.length, normalizedCandidate.length);
    }

    final queryTokens = _tokens(message);
    final candidateTokens = _tokens(normalizedCandidate);
    if (queryTokens.isEmpty || candidateTokens.isEmpty) return 0;
    final common = queryTokens.intersection(candidateTokens).length;
    if (common == 0) return 0;

    final coverage = common / queryTokens.length;
    final precision = common / candidateTokens.length;
    return (coverage * 240 + precision * 100 + common * 25).round();
  }

  Future<OfflineChatMatch?> findMatch(String message, AppLocale locale) async {
    await _loadKnowledgeBase();
    final normalizedMessage = _normalize(message);
    if (normalizedMessage.isEmpty) return null;

    final rawIntents = _knowledgeBase?['intents'];
    if (rawIntents is! List) return null;

    OfflineChatMatch? best;
    for (final rawIntent in rawIntents) {
      if (rawIntent is! Map) continue;
      final intent = Map<String, dynamic>.from(rawIntent);
      final patterns = intent['patterns'];
      final responses = intent['responses'];
      if (patterns is! Map || responses is! Map) continue;

      final languagePatterns = patterns[locale.name];
      final reply = responses[locale.name]?.toString().trim();
      if (languagePatterns is! List || reply == null || reply.isEmpty) continue;

      var intentScore = 0;
      for (final pattern in languagePatterns) {
        intentScore = math.max(
          intentScore,
          _score(normalizedMessage, pattern.toString()),
        );
      }

      // Token matches below this threshold are usually accidental. Exact and
      // phrase matches score above 500, while good multi-word matches exceed 220.
      if (intentScore < 220 || (best != null && intentScore <= best.score)) {
        continue;
      }

      final source = intent['source'];
      best = OfflineChatMatch(
        reply: reply,
        intentId: intent['id']?.toString() ?? '',
        category: intent['category']?.toString() ?? 'general',
        score: intentScore,
        sourceTitle: source is Map ? source['title']?.toString() : null,
        sourceUrl: source is Map ? source['url']?.toString() : null,
      );
    }
    return best;
  }

  Future<String?> findReply(String message, AppLocale locale) async =>
      (await findMatch(message, locale))?.reply;

  Future<String?> getFallback(AppLocale locale) async {
    await _loadKnowledgeBase();
    final rawFallbacks = _knowledgeBase?['fallbacks'];
    if (rawFallbacks is! Map) return null;
    final fallback = rawFallbacks[locale.name]?.toString().trim();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }
}
