import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ContentEntry {
  const ContentEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.phrases,
    required this.examples,
    required this.steps,
    required this.benefits,
    required this.risks,
    required this.relatedIds,
    required this.followUpQuestions,
  });

  factory ContentEntry.fromJson(Map<String, dynamic> json) {
    final question = json['question']?.toString().trim() ?? '';
    return ContentEntry(
      id: json['id']?.toString().trim() ?? question,
      category: json['category']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? question,
      question: question,
      answer: json['answer']?.toString().trim() ?? '',
      keywords: _readStringList(json['keywords']),
      phrases: _readStringList(json['phrases']),
      examples: _readStringList(json['examples']),
      steps: _readStringList(json['steps']),
      benefits: _readStringList(json['benefits']),
      risks: _readStringList(json['risks']),
      relatedIds: _readStringList(json['related_ids']),
      followUpQuestions: _readStringList(json['follow_up_questions']),
    );
  }

  final String id;
  final String category;
  final String title;
  final String question;
  final String answer;
  final List<String> keywords;
  final List<String> phrases;
  final List<String> examples;
  final List<String> steps;
  final List<String> benefits;
  final List<String> risks;
  final List<String> relatedIds;
  final List<String> followUpQuestions;

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final singleValue = value?.toString().trim();
    return singleValue == null || singleValue.isEmpty
        ? const []
        : [singleValue];
  }
}

class _ScoredContentEntry {
  const _ScoredContentEntry(this.entry, this.score);

  final ContentEntry entry;
  final double score;
}

@immutable
class OfflineChatResult {
  const OfflineChatResult({
    required this.answer,
    required this.suggestedQuestions,
    this.matchedContentIds = const [],
    this.matchedEntryId,
    this.matchedCategory,
    this.currentTopic,
  });

  final String answer;
  final List<String> suggestedQuestions;
  final List<String> matchedContentIds;
  final String? matchedEntryId;
  final String? matchedCategory;
  final String? currentTopic;
}

enum _OfflineIntent {
  definition,
  explanation,
  example,
  steps,
  comparison,
  advantages,
  disadvantages,
  followUp,
  generalAdvice,
}

class OfflineLanguageService extends ChangeNotifier {
  OfflineLanguageService._();

  static final OfflineLanguageService instance = OfflineLanguageService._();

  static const defaultLanguageCode = 'en';
  static const prefsKey = 'app_locale';
  static const supportedLanguageCodes = {'en', 'lg', 'sw'};

  static const _languagePackPath = 'assets/language_packs';
  static const _chatPackPath = 'assets/chat_packs';
  static const _contentPackPath = 'assets/content_packs';
  static const _minimumSearchScore = 12.0;

  String _currentLanguageCode = defaultLanguageCode;
  Map<String, String> _languagePack = {};
  Map<String, String> _englishLanguagePack = {};
  Map<String, List<String>> _chatPack = {};
  Map<String, List<String>> _englishChatPack = {};
  List<ContentEntry> _contentEntries = [];

  String get currentLanguageCode => _currentLanguageCode;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await loadLanguage(prefs.getString(prefsKey) ?? defaultLanguageCode);
  }

  Future<void> loadLanguage(String code) async {
    final selectedCode = _supportedOrDefault(code);

    final englishLanguagePack = await _loadLanguagePack(defaultLanguageCode);
    final englishChatPack = await _loadChatPack(defaultLanguageCode);
    final selectedContentPack = await _loadContentPack(selectedCode);

    final selectedLanguagePack =
        selectedCode == defaultLanguageCode
            ? englishLanguagePack
            : await _loadLanguagePack(selectedCode);
    final selectedChatPack =
        selectedCode == defaultLanguageCode
            ? englishChatPack
            : await _loadChatPack(selectedCode);

    _currentLanguageCode = selectedCode;
    _englishLanguagePack = englishLanguagePack;
    _languagePack = selectedLanguagePack;
    _englishChatPack = englishChatPack;
    _chatPack = selectedChatPack;
    _contentEntries = selectedContentPack;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, selectedCode);

    notifyListeners();
  }

  String t(String key) {
    return _languagePack[key] ?? _englishLanguagePack[key] ?? key;
  }

  List<String> getChatResponses(String category) {
    final selectedResponses = _chatPack[category];
    if (selectedResponses != null && selectedResponses.isNotEmpty) {
      return List.unmodifiable(selectedResponses);
    }

    final englishResponses = _englishChatPack[category];
    if (englishResponses != null && englishResponses.isNotEmpty) {
      return List.unmodifiable(englishResponses);
    }

    return [getFallbackResponse()];
  }

  List<ContentEntry> getContentEntries() {
    return List.unmodifiable(_contentEntries);
  }

  List<ContentEntry> searchContent(
    String userMessage, {
    int limit = 3,
    Iterable<String> contextMessages = const [],
  }) {
    if (limit <= 0 || _contentEntries.isEmpty) return const [];

    final normalizedMessage = _normalizeForSearch(userMessage);
    final normalizedContext = _normalizeForSearch(contextMessages.join(' '));
    if (normalizedMessage.isEmpty && normalizedContext.isEmpty) return const [];

    final messageTerms = _searchTerms(normalizedMessage);
    final contextTerms = _searchTerms(normalizedContext);
    final isFollowUp = isFollowUpMessage(normalizedMessage);
    final contextWeight =
        isFollowUp && !_hasTopicHint(messageTerms) ? 0.85 : 0.35;
    final scoredEntries = <_ScoredContentEntry>[];

    for (final entry in _contentEntries) {
      final messageScore =
          normalizedMessage.isEmpty
              ? 0.0
              : _scoreContentEntry(entry, normalizedMessage, messageTerms);
      final contextScore =
          normalizedContext.isEmpty
              ? 0.0
              : _scoreContentEntry(entry, normalizedContext, contextTerms);
      final score = messageScore + (contextScore * contextWeight);
      final minimumScore = isFollowUp ? 8.0 : _minimumSearchScore;

      if (score >= minimumScore && entry.answer.trim().isNotEmpty) {
        scoredEntries.add(_ScoredContentEntry(entry, score));
      }
    }

    scoredEntries.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      return scoreComparison == 0
          ? a.entry.id.compareTo(b.entry.id)
          : scoreComparison;
    });

    return List.unmodifiable(
      scoredEntries.take(limit).map((scored) => scored.entry),
    );
  }

  String getOfflineChatReply(
    String userMessage, {
    Iterable<String> contextMessages = const [],
  }) {
    return getOfflineChatResult(
      userMessage,
      contextMessages: contextMessages,
    ).answer;
  }

  OfflineChatResult getOfflineChatResult(
    String userMessage, {
    Iterable<String> contextMessages = const [],
    String? previousEntryId,
    String? previousCategory,
  }) {
    final intent = _detectIntent(userMessage);
    final isFollowUp =
        intent == _OfflineIntent.followUp || isFollowUpMessage(userMessage);
    final matches = searchContent(
      userMessage,
      contextMessages: contextMessages,
      limit: 8,
    );
    final primary = _selectPrimaryEntry(
      matches,
      isFollowUp: isFollowUp,
      previousEntryId: previousEntryId,
      previousCategory: previousCategory,
    );

    if (primary == null) {
      final answer =
          _firstChatResponse(_chatPack, 'general_help') ??
          _helpfulFallbackAnswer();
      return OfflineChatResult(
        answer: answer,
        suggestedQuestions: getOfflineSuggestedQuestions(
          userMessage,
          contextMessages: contextMessages,
        ),
      );
    }

    final related = _relatedEntries(
      primary,
      matches,
      excludedIds: {primary.id},
      limit: 4,
    );
    final selectedEntries = [primary, ...related];
    return OfflineChatResult(
      answer: _buildReasonedOfflineAnswer(
        userMessage,
        primary: primary,
        related: related,
        intent: intent,
        isFollowUp: isFollowUp,
        isRepeatedTopic: primary.id == previousEntryId,
      ),
      suggestedQuestions: getOfflineSuggestedQuestions(
        userMessage,
        contextMessages: contextMessages,
      ),
      matchedContentIds: List.unmodifiable(
        selectedEntries.map((entry) => entry.id),
      ),
      matchedEntryId: primary.id,
      matchedCategory: primary.category,
      currentTopic: primary.title.isNotEmpty ? primary.title : primary.question,
    );
  }

  List<String> getOfflineSuggestedQuestions(
    String userMessage, {
    Iterable<String> contextMessages = const [],
    int limit = 3,
  }) {
    if (limit <= 0 || _contentEntries.isEmpty) return const [];

    final intent = _detectIntent(userMessage);
    final matches = searchContent(
      userMessage,
      contextMessages: contextMessages,
      limit: 8,
    );
    final suggestions = <String>[];

    void addSuggestion(String question) {
      final trimmedQuestion = question.trim();
      if (trimmedQuestion.isEmpty) return;

      final normalizedQuestion = _normalizeForSearch(trimmedQuestion);
      final normalizedMessage = _normalizeForSearch(userMessage);
      final alreadyAdded = suggestions.any(
        (item) => _normalizeForSearch(item) == normalizedQuestion,
      );

      if (alreadyAdded || normalizedQuestion == normalizedMessage) return;

      suggestions.add(trimmedQuestion);
    }

    void addEntryQuestion(ContentEntry entry) {
      final question = entry.question.trim();
      if (question.isEmpty) return;

      addSuggestion(question);
    }

    if (matches.isNotEmpty) {
      final related = _relatedEntries(
        matches.first,
        matches,
        excludedIds: const {},
        limit: 5,
      );
      final allRelevant = [matches.first, ...related, ...matches.skip(1)];

      for (final entry in allRelevant) {
        if (suggestions.length >= limit) break;
        for (final question in entry.followUpQuestions) {
          addSuggestion(question);
          if (suggestions.length >= limit) break;
        }
      }

      for (final suggestion in _intentSuggestedQuestions(
        intent,
        matches.first,
      )) {
        if (suggestions.length >= limit) break;
        addSuggestion(suggestion);
      }

      final topicTerms = _searchTerms(matches.first.category);
      for (final entry in _contentEntries) {
        if (suggestions.length >= limit) break;
        if (entry.id == matches.first.id) continue;
        if (_hasTermOverlap(topicTerms, _searchTerms(entry.category))) {
          addEntryQuestion(entry);
        }
      }

      for (final entry in matches) {
        if (suggestions.length >= limit) break;
        addEntryQuestion(entry);
      }
    }

    for (final entry in _contentEntries) {
      if (suggestions.length >= limit) break;
      if (_normalizeForSearch(entry.category).contains('greeting') ||
          _normalizeForSearch(entry.category).contains('salamu') ||
          _normalizeForSearch(entry.category).contains('okulamusa')) {
        continue;
      }
      addEntryQuestion(entry);
    }

    return List.unmodifiable(suggestions.take(limit));
  }

  String buildGroqContext(
    String userMessage, {
    Iterable<String> contextMessages = const [],
  }) {
    final matches = searchContent(
      userMessage,
      contextMessages: contextMessages,
      limit: 8,
    );
    final entries =
        matches.isEmpty
            ? const <ContentEntry>[]
            : [
              matches.first,
              ..._relatedEntries(
                matches.first,
                matches,
                excludedIds: {matches.first.id},
                limit: 4,
              ),
              ...matches.skip(1),
            ].fold<List<ContentEntry>>([], (unique, entry) {
              if (!unique.any((item) => item.id == entry.id) &&
                  unique.length < 5) {
                unique.add(entry);
              }
              return unique;
            });
    if (entries.isEmpty) return '';

    final buffer =
        StringBuffer()
          ..writeln(
            'Human-reviewed Africa AI Connect reference context for the '
            'selected language ($_currentLanguageCode).',
          )
          ..writeln(
            'Reason from these entries when relevant. Do not copy the answers '
            'directly. Connect related ideas, stay practical, and do not '
            'contradict this context.',
          );

    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      buffer
        ..writeln()
        ..writeln('Reference ${index + 1}')
        ..writeln('ID: ${entry.id}')
        ..writeln('Category: ${entry.category}')
        ..writeln('Title: ${entry.title}')
        ..writeln('Question: ${entry.question}')
        ..writeln('Answer: ${entry.answer}');

      if (entry.keywords.isNotEmpty) {
        buffer.writeln('Keywords: ${entry.keywords.join(', ')}');
      }
      if (entry.examples.isNotEmpty) {
        buffer.writeln('Examples: ${entry.examples.join(' | ')}');
      }
      if (entry.steps.isNotEmpty) {
        buffer.writeln('Steps: ${entry.steps.join(' | ')}');
      }
      if (entry.benefits.isNotEmpty) {
        buffer.writeln('Benefits: ${entry.benefits.join(' | ')}');
      }
      if (entry.risks.isNotEmpty) {
        buffer.writeln('Risks: ${entry.risks.join(' | ')}');
      }
      if (entry.relatedIds.isNotEmpty) {
        buffer.writeln('Related IDs: ${entry.relatedIds.join(', ')}');
      }
      if (entry.followUpQuestions.isNotEmpty) {
        buffer.writeln(
          'Follow-up questions: ${entry.followUpQuestions.join(' | ')}',
        );
      }
    }

    return buffer.toString().trim();
  }

  String getFallbackResponse() {
    final selectedFallback = _chatPack['fallback'];
    if (selectedFallback != null && selectedFallback.isNotEmpty) {
      return selectedFallback.first;
    }

    final englishFallback = _englishChatPack['fallback'];
    if (englishFallback != null && englishFallback.isNotEmpty) {
      return englishFallback.first;
    }

    return t('error_general');
  }

  String? _firstChatResponse(
    Map<String, List<String>> chatPack,
    String category,
  ) {
    final responses = chatPack[category];
    if (responses == null || responses.isEmpty) return null;

    final first = responses.first.trim();
    return first.isEmpty ? null : first;
  }

  ContentEntry? _selectPrimaryEntry(
    List<ContentEntry> matches, {
    required bool isFollowUp,
    String? previousEntryId,
    String? previousCategory,
  }) {
    if (matches.isEmpty) return null;

    if (!isFollowUp) return matches.first;

    if (previousCategory != null && previousCategory.trim().isNotEmpty) {
      final previousCategoryTerms = _searchTerms(previousCategory);
      for (final entry in matches) {
        if (entry.id == previousEntryId) continue;
        if (_hasTermOverlap(
          previousCategoryTerms,
          _searchTerms(entry.category),
        )) {
          return entry;
        }
      }
    }

    for (final entry in matches) {
      if (entry.id != previousEntryId) return entry;
    }

    return matches.first;
  }

  List<ContentEntry> _relatedEntries(
    ContentEntry primary,
    List<ContentEntry> matches, {
    required Set<String?> excludedIds,
    required int limit,
  }) {
    final related = <ContentEntry>[];
    final primaryTerms = {
      ..._searchTerms(primary.category),
      ..._searchTerms(primary.title),
      ...primary.keywords.expand(_searchTerms),
    };
    final relatedIdSet = primary.relatedIds.toSet();

    void addEntry(ContentEntry entry) {
      if (related.length >= limit || excludedIds.contains(entry.id)) return;

      final alreadyAdded = related.any((item) => item.id == entry.id);
      if (!alreadyAdded) related.add(entry);
    }

    for (final entry in matches) {
      final isRelatedById =
          relatedIdSet.contains(entry.id) ||
          entry.relatedIds.contains(primary.id);
      final isRelatedByTopic = _hasTermOverlap(primaryTerms, {
        ..._searchTerms(entry.category),
        ..._searchTerms(entry.title),
        ...entry.keywords.expand(_searchTerms),
      });
      if (isRelatedById || isRelatedByTopic) {
        addEntry(entry);
      }
    }

    for (final entry in _contentEntries) {
      if (related.length >= limit) break;
      final isRelatedById =
          relatedIdSet.contains(entry.id) ||
          entry.relatedIds.contains(primary.id);
      final isRelatedByTopic = _hasTermOverlap(primaryTerms, {
        ..._searchTerms(entry.category),
        ..._searchTerms(entry.title),
        ...entry.keywords.expand(_searchTerms),
      });
      if (isRelatedById || isRelatedByTopic) {
        addEntry(entry);
      }
    }

    return List.unmodifiable(related);
  }

  String _buildReasonedOfflineAnswer(
    String userMessage, {
    required ContentEntry primary,
    required List<ContentEntry> related,
    _OfflineIntent? intent,
    required bool isFollowUp,
    required bool isRepeatedTopic,
  }) {
    final resolvedIntent = intent ?? _detectIntent(userMessage);
    final parts = <String>[];
    final bridge = _followUpBridge(primary);

    if (isFollowUp && bridge.isNotEmpty) {
      parts.add(bridge);
    }

    switch (resolvedIntent) {
      case _OfflineIntent.definition:
        parts.add(_definitionAnswer(primary, related));
        break;
      case _OfflineIntent.example:
        parts.add(_exampleAnswer(primary, related));
        break;
      case _OfflineIntent.steps:
        parts.add(_stepsAnswer(primary, related));
        break;
      case _OfflineIntent.comparison:
        parts.add(_comparisonAnswer(primary, related));
        break;
      case _OfflineIntent.advantages:
        parts.add(_advantagesAnswer(primary, related));
        break;
      case _OfflineIntent.disadvantages:
        parts.add(_risksAnswer(primary, related));
        break;
      case _OfflineIntent.explanation:
      case _OfflineIntent.followUp:
      case _OfflineIntent.generalAdvice:
        parts.add(
          _generalReasonedAnswer(
            primary,
            related,
            isRepeatedTopic: isRepeatedTopic,
          ),
        );
        break;
    }

    final guidance = _categoryGuidance(primary.category);
    if (guidance.isNotEmpty) {
      parts.add(guidance);
    }

    return parts.where((part) => part.trim().isNotEmpty).join('\n\n');
  }

  String _definitionAnswer(ContentEntry primary, List<ContentEntry> related) {
    final pieces = <String>['${_label('direct')}: ${_coreIdea(primary)}'];

    final examples = _collectValues(
      primary,
      related,
      (entry) => entry.examples,
    );
    if (examples.isNotEmpty) {
      pieces.add('${_label('example')}: ${examples.first}');
    }

    final benefits = _collectValues(
      primary,
      related,
      (entry) => entry.benefits,
    );
    if (benefits.isNotEmpty) {
      pieces.add('${_label('why')}: ${benefits.first}');
    }

    final steps = _collectValues(primary, related, (entry) => entry.steps);
    if (steps.isNotEmpty) {
      pieces.add('${_label('next')}: ${steps.first}');
    }

    return pieces.join('\n');
  }

  String _exampleAnswer(ContentEntry primary, List<ContentEntry> related) {
    final examples = _collectValues(
      primary,
      related,
      (entry) => entry.examples,
    );
    final pieces = <String>[];

    if (examples.isNotEmpty) {
      pieces.add('${_label('example')}: ${examples.first}');
      if (examples.length > 1) {
        pieces.add(_bulletList(examples.skip(1).take(2)));
      }
    } else {
      pieces.add('${_label('example')}: ${_coreIdea(primary)}');
    }

    pieces.add('${_label('means')}: ${_firstSentence(primary.answer)}');

    final relatedInsight = _relatedInsight(related);
    if (relatedInsight.isNotEmpty) {
      pieces.add('${_relatedLeadIn()} $relatedInsight');
    }

    return pieces.join('\n');
  }

  String _stepsAnswer(ContentEntry primary, List<ContentEntry> related) {
    final steps = _collectValues(primary, related, (entry) => entry.steps);
    final usableSteps =
        steps.isNotEmpty ? steps.take(5).toList() : _stepsFromText(primary);
    final pieces = <String>[
      '${_label('direct')}: ${_firstSentence(primary.answer)}',
      _numberedList(usableSteps.take(5)),
    ];

    final risks = _collectValues(primary, related, (entry) => entry.risks);
    if (risks.isNotEmpty) {
      pieces.add('${_label('caution')}: ${risks.first}');
    } else {
      final relatedInsight = _relatedInsight(related);
      if (relatedInsight.isNotEmpty) {
        pieces.add('${_label('tip')}: $relatedInsight');
      }
    }

    return pieces.where((piece) => piece.trim().isNotEmpty).join('\n');
  }

  String _comparisonAnswer(ContentEntry primary, List<ContentEntry> related) {
    final other = related.isNotEmpty ? related.first : null;
    if (other == null) {
      return _generalReasonedAnswer(primary, related, isRepeatedTopic: false);
    }

    return [
      '${_label('compare')}:',
      '- ${_entryTopic(primary)}: ${_firstSentence(primary.answer)}',
      '- ${_entryTopic(other)}: ${_firstSentence(other.answer)}',
      '${_label('use')}: ${_comparisonUseCase(primary, other)}',
    ].join('\n');
  }

  String _advantagesAnswer(ContentEntry primary, List<ContentEntry> related) {
    final benefits = _collectValues(
      primary,
      related,
      (entry) => entry.benefits,
    );
    final pieces = <String>[
      '${_label('direct')}: ${_firstSentence(primary.answer)}',
    ];

    if (benefits.isNotEmpty) {
      pieces.add(_bulletList(benefits.take(4)));
    } else {
      pieces.add('${_label('why')}: ${_relatedInsight(related)}');
    }

    final risks = _collectValues(primary, related, (entry) => entry.risks);
    if (risks.isNotEmpty) {
      pieces.add('${_label('limit')}: ${risks.first}');
    }

    return pieces.where((piece) => piece.trim().isNotEmpty).join('\n');
  }

  String _risksAnswer(ContentEntry primary, List<ContentEntry> related) {
    final risks = _collectValues(primary, related, (entry) => entry.risks);
    final pieces = <String>[
      '${_label('direct')}: ${_firstSentence(primary.answer)}',
    ];

    if (risks.isNotEmpty) {
      pieces.add(_bulletList(risks.take(4)));
    } else {
      pieces.add('${_label('caution')}: ${_fallbackCaution(primary)}');
    }

    final steps = _collectValues(primary, related, (entry) => entry.steps);
    if (steps.isNotEmpty) {
      pieces.add('${_label('next')}: ${steps.first}');
    }

    return pieces.join('\n');
  }

  String _generalReasonedAnswer(
    ContentEntry primary,
    List<ContentEntry> related, {
    required bool isRepeatedTopic,
  }) {
    final pieces = <String>[];
    if (!isRepeatedTopic || related.isEmpty) {
      pieces.add('${_label('direct')}: ${primary.answer}');
    } else {
      pieces.add('${_label('direct')}: ${_firstSentence(primary.answer)}');
    }

    final examples = _collectValues(
      primary,
      related,
      (entry) => entry.examples,
    );
    if (examples.isNotEmpty) {
      pieces.add('${_label('example')}: ${examples.first}');
    }

    final steps = _collectValues(primary, related, (entry) => entry.steps);
    if (steps.isNotEmpty) {
      pieces.add('${_label('next')}: ${steps.first}');
    }

    final relatedInsight = _relatedInsight(related);
    if (relatedInsight.isNotEmpty) {
      pieces.add('${_relatedLeadIn()} $relatedInsight');
    }

    return pieces.join('\n');
  }

  List<String> _stepsFromText(ContentEntry entry) {
    final sentences = _sentences(entry.answer);
    if (sentences.length >= 3) return sentences.take(5).toList();

    final fragments =
        entry.answer
            .split(RegExp(r',|\band\b'))
            .map((item) => item.trim())
            .where((item) => item.length > 10)
            .take(5)
            .toList();

    return fragments.isEmpty ? [_firstSentence(entry.answer)] : fragments;
  }

  String _coreIdea(ContentEntry entry) {
    if (entry.title.isNotEmpty) {
      return '${entry.title}: ${_firstSentence(entry.answer)}';
    }

    return _firstSentence(entry.answer);
  }

  String _relatedInsight(List<ContentEntry> related) {
    final insights =
        related
            .map((entry) => _firstSentence(entry.answer))
            .where((item) => item.trim().isNotEmpty)
            .take(2)
            .toList();

    return insights.join(' ');
  }

  String _comparisonUseCase(ContentEntry primary, ContentEntry other) {
    final primaryStep = primary.steps.isNotEmpty ? primary.steps.first : '';
    final otherStep = other.steps.isNotEmpty ? other.steps.first : '';
    final values =
        [
          primaryStep,
          otherStep,
        ].where((item) => item.trim().isNotEmpty).toList();

    if (values.isEmpty) {
      return _currentLanguageCode == 'sw'
          ? 'Tumia kila wazo pale linapolingana na lengo lako.'
          : _currentLanguageCode == 'lg'
          ? 'Kozesa buli nsonga mu kifo ekigendererwa kyo gye kikwatagana.'
          : 'Use each idea where it matches your goal.';
    }

    return values.join(' ');
  }

  String _fallbackCaution(ContentEntry entry) {
    final normalizedCategory = _normalizeForSearch(entry.category);
    if (_categoryContains(normalizedCategory, const [
      'health',
      'obulamu',
      'afya',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Bw\'oba n\'obubonero obw\'amaanyi oba obweyongera, funa omusawo mangu.';
        case 'sw':
          return 'Dalili zikiwa kali au zinazidi, tafuta mhudumu wa afya mapema.';
        default:
          return 'If symptoms are serious or getting worse, seek medical help early.';
      }
    }

    switch (_currentLanguageCode) {
      case 'lg':
        return 'Tandika n\'ekitono, kakasa abantu n\'ensimbi, era weewale okusaasaanya ennyo nga tonnagezesezza.';
      case 'sw':
        return 'Anza kidogo, hakikisha watu na pesa, na epuka kutumia sana kabla hujajaribu.';
      default:
        return 'Start small, verify people and money, and avoid spending heavily before testing.';
    }
  }

  List<String> _collectValues(
    ContentEntry primary,
    List<ContentEntry> related,
    List<String> Function(ContentEntry entry) selector,
  ) {
    final values = <String>[];
    for (final entry in [primary, ...related]) {
      for (final value in selector(entry)) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) continue;
        final exists = values.any(
          (item) => _normalizeForSearch(item) == _normalizeForSearch(trimmed),
        );
        if (!exists) values.add(trimmed);
      }
    }

    return values;
  }

  String _entryTopic(ContentEntry entry) {
    if (entry.title.trim().isNotEmpty) return entry.title.trim();
    if (entry.question.trim().isNotEmpty) return entry.question.trim();
    return entry.category.trim();
  }

  String _firstSentence(String text) {
    final sentences = _sentences(text);
    return sentences.isEmpty ? text.trim() : sentences.first;
  }

  List<String> _sentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _numberedList(Iterable<String> values) {
    final items = values.where((item) => item.trim().isNotEmpty).toList();
    if (items.isEmpty) return '';

    return List.generate(
      items.length,
      (index) => '${index + 1}. ${items[index].trim()}',
    ).join('\n');
  }

  String _bulletList(Iterable<String> values) {
    final items = values.where((item) => item.trim().isNotEmpty).toList();
    if (items.isEmpty) return '';

    return items.map((item) => '- ${item.trim()}').join('\n');
  }

  String _label(String key) {
    switch (_currentLanguageCode) {
      case 'lg':
        return switch (key) {
          'direct' => 'Ekiddamu ekikulu',
          'example' => 'Ekyokulabirako',
          'why' => 'Lwaki kikulu',
          'next' => 'Omutendera oguddako',
          'means' => 'Ekiri mu kino',
          'caution' => 'Weegendereze',
          'tip' => 'Amagezi ag\'okukozesa',
          'compare' => 'Enjawulo',
          'use' => 'Ddi lwe kikola obulungi',
          'limit' => 'Awayinza okuba ekizibu',
          _ => key,
        };
      case 'sw':
        return switch (key) {
          'direct' => 'Jibu kuu',
          'example' => 'Mfano',
          'why' => 'Kwa nini ni muhimu',
          'next' => 'Hatua inayofuata',
          'means' => 'Kinachotokea hapa',
          'caution' => 'Tahadhari',
          'tip' => 'Kidokezo cha vitendo',
          'compare' => 'Ulinganisho',
          'use' => 'Wakati wa kutumia',
          'limit' => 'Mahali pasipofaa sana',
          _ => key,
        };
      default:
        return switch (key) {
          'direct' => 'Direct answer',
          'example' => 'Example',
          'why' => 'Why it matters',
          'next' => 'Next step',
          'means' => 'What is happening',
          'caution' => 'Caution',
          'tip' => 'Practical tip',
          'compare' => 'Comparison',
          'use' => 'When to use it',
          'limit' => 'Where it may not work well',
          _ => key,
        };
    }
  }

  String _followUpBridge(ContentEntry primary) {
    final topic = primary.title.isNotEmpty ? primary.title : primary.question;
    switch (_currentLanguageCode) {
      case 'lg':
        return 'Ka tweyongere ku nsonga ya $topic.';
      case 'sw':
        return 'Tuendelee na mada ya $topic.';
      default:
        return 'Building on $topic.';
    }
  }

  String _relatedLeadIn() {
    switch (_currentLanguageCode) {
      case 'lg':
        return 'Ekirala ekikwatagana nakyo:';
      case 'sw':
        return 'Jambo lingine linalohusiana:';
      default:
        return 'A related point:';
    }
  }

  String _helpfulFallbackAnswer() {
    switch (_currentLanguageCode) {
      case 'lg':
        return 'Nsobola okukuyamba ku busubuzi, bulimi, nsimbi, bulamu, mirimu, obukugu bwa ssimu, n\'ekibiina. Buuza ekibuuzo kimu mu bigambo ebyangu, nja kukuyamba mu mitendera.';
      case 'sw':
        return 'Ninaweza kusaidia kuhusu biashara, kilimo, pesa, afya, kazi, ujuzi wa simu, na jamii. Uliza swali moja kwa maneno rahisi, nami nitakusaidia kwa hatua.';
      default:
        return 'I can help with business, farming, money, health, jobs, digital skills, online selling, and community questions. Ask one clear question, and I will help step by step.';
    }
  }

  String _categoryGuidance(String category) {
    final normalized = _normalizeForSearch(category);

    if (_categoryContains(normalized, const [
      'business',
      'obusubuzi',
      'biashara',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Kino kikole mu ngeri eyangu: londa bakasitoma b\'oyagala okuweereza, manya ensaasaanya yo, teekawo bbeeyi ekuwa amagoba, era wandiika buli kyotunda.';
        case 'sw':
          return 'Ifanye kwa vitendo: tambua wateja unaowalenga, jua gharama zako, weka bei yenye faida, na andika kila unachouza.';
        default:
          return 'Make it practical: choose the customers you want to serve, know your costs, set a price that leaves profit, and record every sale.';
      }
    }

    if (_categoryContains(normalized, const [
      'financial',
      'savings',
      'money',
      'ensimbi',
      'fedha',
      'akiba',
      'mobile',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Tandika n\'akatono k\'osobola okukola buli kiseera. Yawula ssente z\'awaka ku z\'omulimu, era weekebereze ensaasaanya buli wiiki.';
        case 'sw':
          return 'Anza na kiasi kidogo unachoweza kurudia mara kwa mara. Tenganisha pesa ya nyumbani na ya kazi, kisha kagua matumizi kila wiki.';
        default:
          return 'Start with a small habit you can repeat. Separate home money from work money, then review spending every week.';
      }
    }

    if (_categoryContains(normalized, const [
      'farming',
      'agriculture',
      'obulimi',
      'kilimo',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Mu bulimi, tandika n\'ekitundu ekitono, goberera sizoni n\'amazzi g\'olina, era buuza omukugu w\'ebyobulimi nga tonnasaasaanya nnyo.';
        case 'sw':
          return 'Katika kilimo, anza na eneo dogo, fuata msimu na maji uliyonayo, na uliza afisa ugani kabla ya kutumia pesa nyingi.';
        default:
          return 'For farming, start with a small area, match the season and water you have, and ask an extension worker before spending heavily.';
      }
    }

    if (_categoryContains(normalized, const [
      'health',
      'nutrition',
      'obulamu',
      'afya',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Ku nsonga z\'obulamu, kola ku byangu ebikuuma: amazzi amayonjo, emmere ey\'enjawulo, okuwummula, n\'okufuna omusawo mangu obubonero bwe bweyongera.';
        case 'sw':
          return 'Kwa afya, shikilia mambo ya msingi: maji safi, chakula bora, kupumzika, na kutafuta mhudumu wa afya mapema dalili zikizidi.';
        default:
          return 'For health, focus on the basics: clean water, balanced meals, rest, and early care if symptoms worsen.';
      }
    }

    if (_categoryContains(normalized, const [
      'job',
      'career',
      'cv',
      'emirimu',
      'kazi',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Ku mirimu, tegeka CV ennyimpi, laga obukugu bw\'olina, saba emirimu egikukwatako, era oddemu okubuuza mu ngeri ey\'ekitiibwa.';
        case 'sw':
          return 'Kwa kazi, andaa CV fupi, onyesha ujuzi ulionao, omba kazi zinazokufaa, na fuatilia kwa heshima.';
        default:
          return 'For jobs, prepare a short CV, show the skills you already have, apply for suitable roles, and follow up politely.';
      }
    }

    if (_categoryContains(normalized, const [
      'digital',
      'phone',
      'internet',
      'obukugu',
      'ssimu',
      'simu',
      'intaneti',
      'yintaneeti',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Ku bukugu bwa ssimu, yiga ekintu kimu buli lunaku: okunoonyereza, obukuumi bwa PIN, okukuba ebifaananyi, oba okuwandiika ebiwandiiko ebyangu.';
        case 'sw':
          return 'Kwa ujuzi wa simu, jifunze jambo moja kila siku: kutafuta taarifa, kulinda PIN, kupiga picha wazi, au kuweka rekodi rahisi.';
        default:
          return 'For digital skills, practise one small thing each day: searching, PIN safety, clear photos, or simple records.';
      }
    }

    if (_categoryContains(normalized, const [
      'online',
      'selling',
      'marketplace',
      'okutunda',
      'kuuza',
      'mtandaoni',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Nga otunda ku mutimbagano, ebifaananyi bitegeerekeke, bbeeyi ebeere mu lwatu, era kakasa okusasulwa nga tonnatwala kintu.';
        case 'sw':
          return 'Unapouza mtandaoni, tumia picha zilizo wazi, bei iwe wazi, na thibitisha malipo kabla ya kupeleka bidhaa.';
        default:
          return 'When selling online, use clear photos, make the price clear, and confirm payment before delivery.';
      }
    }

    if (_categoryContains(normalized, const [
      'community',
      'group',
      'leadership',
      'ekibiina',
      'jamii',
      'kikundi',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Mu kibiina, amateeka amalambulukufu, ebiwandiiko eby\'amazima, n\'okusalawo mu lwatu biyamba abantu okwesigagana.';
        case 'sw':
          return 'Katika kikundi, sheria zilizo wazi, rekodi za kweli, na maamuzi ya wazi husaidia watu kuaminiana.';
        default:
          return 'In a group, clear rules, honest records, and open decisions help people trust each other.';
      }
    }

    if (_categoryContains(normalized, const [
      'wellbeing',
      'safety',
      'stress',
      'ustawi',
      'usalama',
      'msongo',
      'obukuumi',
      'situleesi',
    ])) {
      switch (_currentLanguageCode) {
        case 'lg':
          return 'Bw\'oba owulira situleesi oba obutali bukuumi, sooka ofune ekifo ekikuuma, yogera n\'omuntu gwe weesiga, era tuukirira obuyambi obwesigika.';
        case 'sw':
          return 'Ukihisi msongo au hauko salama, tafuta sehemu salama kwanza, zungumza na mtu unayemwamini, na wasiliana na msaada unaoaminika.';
        default:
          return 'If you feel stressed or unsafe, first move toward safety, talk to someone you trust, and contact trusted support.';
      }
    }

    return '';
  }

  bool _categoryContains(String normalizedCategory, List<String> terms) {
    return terms.any(normalizedCategory.contains);
  }

  String _supportedOrDefault(String code) {
    final normalized = _normalizeLanguageCode(code);
    return supportedLanguageCodes.contains(normalized)
        ? normalized
        : defaultLanguageCode;
  }

  String _normalizeLanguageCode(String code) {
    final normalized = code.trim().toLowerCase();
    switch (normalized) {
      case 'english':
        return 'en';
      case 'luganda':
      case 'ganda':
        return 'lg';
      case 'kiswahili':
      case 'swahili':
        return 'sw';
      default:
        return normalized;
    }
  }

  Future<Map<String, String>> _loadLanguagePack(String code) async {
    final raw = await rootBundle.loadString('$_languagePackPath/$code.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<Map<String, List<String>>> _loadChatPack(String code) async {
    final raw = await rootBundle.loadString('$_chatPackPath/${code}_chat.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final responses =
          value is List
              ? value.map((item) => item.toString()).toList()
              : <String>[value.toString()];
      return MapEntry(key, responses);
    });
  }

  Future<List<ContentEntry>> _loadContentPack(String code) async {
    try {
      final raw = await rootBundle.loadString(
        '$_contentPackPath/${code}_content.json',
      );
      final decoded = jsonDecode(raw);
      final entriesJson =
          decoded is Map<String, dynamic> ? decoded['entries'] : decoded;

      if (entriesJson is! List) return const [];

      return entriesJson
          .whereType<Map>()
          .map((item) => ContentEntry.fromJson(Map<String, dynamic>.from(item)))
          .where((entry) => entry.answer.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  double _scoreContentEntry(
    ContentEntry entry,
    String normalizedMessage,
    Set<String> messageTerms,
  ) {
    var score = 0.0;

    score += _phraseScore(entry.title, normalizedMessage, 56, 24, 14);
    score += _phraseScore(entry.question, normalizedMessage, 70, 30, 16);

    for (final phrase in entry.phrases) {
      score += _phraseScore(phrase, normalizedMessage, 60, 42, 16);
    }

    final normalizedCategory = _normalizeForSearch(entry.category);
    if (normalizedCategory.isNotEmpty &&
        normalizedMessage.contains(normalizedCategory)) {
      score += 24;
    }
    score += _cappedOverlapScore(
      messageTerms,
      _searchTerms(entry.category),
      8,
      24,
    );

    for (final keyword in entry.keywords) {
      final normalizedKeyword = _normalizeForSearch(keyword);
      if (normalizedKeyword.isEmpty) continue;

      if (normalizedKeyword == normalizedMessage) {
        score += 35;
      } else if (normalizedKeyword.length > 1 &&
          normalizedMessage.contains(normalizedKeyword)) {
        score += 22;
      } else {
        score += _cappedOverlapScore(
          messageTerms,
          _searchTerms(normalizedKeyword),
          7,
          14,
        );
      }
    }

    score += _cappedOverlapScore(
      messageTerms,
      _searchTerms(entry.question),
      5,
      30,
    );
    score += _cappedOverlapScore(
      messageTerms,
      _searchTerms(entry.answer),
      2,
      14,
    );
    score += _cappedListOverlapScore(messageTerms, entry.examples, 3, 18);
    score += _cappedListOverlapScore(messageTerms, entry.steps, 4, 22);
    score += _cappedListOverlapScore(messageTerms, entry.benefits, 4, 22);
    score += _cappedListOverlapScore(messageTerms, entry.risks, 5, 24);
    score += _cappedListOverlapScore(
      messageTerms,
      entry.followUpQuestions,
      4,
      22,
    );

    return score;
  }

  double _cappedListOverlapScore(
    Set<String> messageTerms,
    Iterable<String> values,
    double weight,
    double cap,
  ) {
    var score = 0.0;
    for (final value in values) {
      score += _cappedOverlapScore(
        messageTerms,
        _searchTerms(value),
        weight,
        cap,
      );
      if (score >= cap) return cap;
    }

    return score;
  }

  double _phraseScore(
    String value,
    String normalizedMessage,
    double exactScore,
    double containsScore,
    double reverseContainsScore,
  ) {
    final normalizedValue = _normalizeForSearch(value);
    if (normalizedValue.isEmpty) return 0;

    if (normalizedValue == normalizedMessage) return exactScore;
    if (normalizedValue.length > 1 &&
        normalizedMessage.contains(normalizedValue)) {
      return containsScore;
    }
    if (normalizedMessage.length >= 8 &&
        normalizedValue.contains(normalizedMessage)) {
      return reverseContainsScore;
    }

    return 0;
  }

  double _cappedOverlapScore(
    Set<String> first,
    Set<String> second,
    double weight,
    double cap,
  ) {
    if (first.isEmpty || second.isEmpty) return 0;

    var count = 0;
    for (final term in first) {
      if (second.contains(term)) count += 1;
    }

    final score = count * weight;
    return score > cap ? cap : score.toDouble();
  }

  bool _hasTermOverlap(Set<String> first, Set<String> second) {
    if (first.isEmpty || second.isEmpty) return false;

    for (final term in first) {
      if (second.contains(term)) return true;
    }
    return false;
  }

  bool _hasTopicHint(Set<String> terms) {
    if (terms.isEmpty) return false;

    for (final term in terms) {
      if (_topicHints.contains(term)) return true;
    }
    return false;
  }

  _OfflineIntent _detectIntent(String userMessage) {
    final normalized = _normalizeForSearch(userMessage);
    if (normalized.isEmpty) return _OfflineIntent.followUp;

    if (_containsAny(normalized, const [
      'example',
      'examples',
      'scenario',
      'ebyokulabirako',
      'kyokulabirako',
      'mifano',
      'mfano',
    ])) {
      return _OfflineIntent.example;
    }

    if (_containsAny(normalized, const [
      'advantage',
      'advantages',
      'benefit',
      'benefits',
      'why is it good',
      'why is this good',
      'importance',
      'omugaso',
      'migaso',
      'lwaki kikulu',
      'faida',
      'manufaa',
      'umuhimu',
    ])) {
      return _OfflineIntent.advantages;
    }

    if (_containsAny(normalized, const [
      'risk',
      'risks',
      'disadvantage',
      'disadvantages',
      'danger',
      'problem',
      'problems',
      'scam',
      'fraud',
      'akabi',
      'obuzibu',
      'obulimba',
      'hatari',
      'changamoto',
      'utapeli',
    ])) {
      return _OfflineIntent.disadvantages;
    }

    if (_containsAny(normalized, const [
      'compare',
      'comparison',
      'difference',
      'different',
      'versus',
      'vs',
      'which is better',
      'enjawulo',
      'kyawukana',
      'geraageranya',
      'tofauti',
      'linganisha',
      'bora ipi',
    ])) {
      return _OfflineIntent.comparison;
    }

    if (_containsAny(normalized, const [
      'how do i',
      'how can i',
      'how to',
      'steps',
      'step by step',
      'start',
      'begin',
      'what should i do',
      'nkola ntya',
      'ntandika ntya',
      'mitendera',
      'ninawezaje',
      'jinsi ya',
      'hatua',
      'nianze',
      'nifanye nini',
    ])) {
      return _OfflineIntent.steps;
    }

    if (_containsAny(normalized, const [
      'what is',
      'what are',
      'meaning',
      'define',
      'definition',
      'kiki',
      'kitegeeza',
      'nini',
      'maana',
    ])) {
      return _OfflineIntent.definition;
    }

    if (_containsAny(normalized, const [
      'explain',
      'explain more',
      'tell me more',
      'deeply',
      'details',
      'nnyonnyola',
      'ongera okunnyonnyola',
      'eleza',
      'eleza zaidi',
      'fafanua',
    ])) {
      return _OfflineIntent.explanation;
    }

    if (isFollowUpMessage(normalized)) return _OfflineIntent.followUp;

    return _OfflineIntent.generalAdvice;
  }

  List<String> _intentSuggestedQuestions(
    _OfflineIntent intent,
    ContentEntry entry,
  ) {
    final topic = _entryTopic(entry);
    switch (_currentLanguageCode) {
      case 'lg':
        return switch (intent) {
          _OfflineIntent.definition => [
            'Nnyinza ntya okukozesa $topic mu bulamu bwa buli lunaku?',
            'Mpa ekyokulabirako kya $topic.',
          ],
          _OfflineIntent.steps => [
            'Kiki kye nsaanidde okusooka okukola?',
            'Buzibu ki bwe nsaanidde okwegendereza?',
          ],
          _OfflineIntent.example => [
            'Nnyonnyola omutendera oguddako.',
            'Kino nnyinza ntya okukikozesa mu busubuzi?',
          ],
          _OfflineIntent.advantages => [
            'Buzibu ki obuyinza okubaawo?',
            'Ntandika ntya mu ngeri eyangu?',
          ],
          _OfflineIntent.disadvantages => [
            'Nnyinza ntya okwewala obuzibu obwo?',
            'Kiki kye nsaanidde okukakasa nga tonnatandika?',
          ],
          _OfflineIntent.comparison => [
            'Kiruwa ekisinga ku mbeera yange?',
            'Mpa ekyokulabirako ekyangu.',
          ],
          _ => ['Nnyonnyola ekyo mu bujjuvu.', 'Mpa emitendera egyangu.'],
        };
      case 'sw':
        return switch (intent) {
          _OfflineIntent.definition => [
            'Ninawezaje kutumia $topic katika maisha ya kila siku?',
            'Nipe mfano wa $topic.',
          ],
          _OfflineIntent.steps => [
            'Nianze na hatua gani kwanza?',
            'Ni changamoto gani niangalie?',
          ],
          _OfflineIntent.example => [
            'Eleza hatua inayofuata.',
            'Ninawezaje kutumia hili kwenye biashara?',
          ],
          _OfflineIntent.advantages => [
            'Ni hatari au changamoto gani zipo?',
            'Ninawezaje kuanza kwa njia rahisi?',
          ],
          _OfflineIntent.disadvantages => [
            'Ninawezaje kuepuka changamoto hizo?',
            'Nihakikishe nini kabla ya kuanza?',
          ],
          _OfflineIntent.comparison => [
            'Kipi kinafaa zaidi kwa hali yangu?',
            'Nipe mfano rahisi.',
          ],
          _ => ['Eleza hilo kwa undani zaidi.', 'Nipe hatua rahisi.'],
        };
      default:
        return switch (intent) {
          _OfflineIntent.definition => [
            'How can I use $topic in daily life?',
            'Can you give a practical example of $topic?',
          ],
          _OfflineIntent.steps => [
            'What should I do first?',
            'What risks should I watch for?',
          ],
          _OfflineIntent.example => [
            'Explain the next step.',
            'How can I use this in business?',
          ],
          _OfflineIntent.advantages => [
            'What risks or limits should I know?',
            'How can I start in a simple way?',
          ],
          _OfflineIntent.disadvantages => [
            'How can I avoid those problems?',
            'What should I check before I start?',
          ],
          _OfflineIntent.comparison => [
            'Which option fits my situation better?',
            'Can you give a simple example?',
          ],
          _ => [
            'Can you explain that in more detail?',
            'Can you give me simple steps?',
          ],
        };
    }
  }

  bool _containsAny(String normalizedMessage, Iterable<String> values) {
    for (final value in values) {
      if (normalizedMessage.contains(_normalizeForSearch(value))) {
        return true;
      }
    }
    return false;
  }

  Set<String> _searchTerms(String value) {
    final normalized = _normalizeForSearch(value);
    if (normalized.isEmpty) return const {};

    return normalized
        .split(' ')
        .where((term) => term.length > 1 && !_stopWords.contains(term))
        .toSet();
  }

  bool isFollowUpMessage(String message) {
    final normalizedMessage = _normalizeForSearch(message);
    if (normalizedMessage.isEmpty) return true;

    final terms = _searchTerms(normalizedMessage);
    if (terms.length <= 2 &&
        normalizedMessage.length <= 32 &&
        !_hasTopicHint(terms)) {
      return true;
    }

    return _followUpPhrases.any(normalizedMessage.contains);
  }

  String _normalizeForSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-/]'), ' ')
        .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _followUpPhrases = {
    'explain more',
    'tell me more',
    'give examples',
    'more examples',
    'what about',
    'how can i start',
    'how do i start',
    'next step',
    'steps',
    'ekirala',
    'nnyonnyola',
    'ongera okunnyonnyola',
    'mpa ebyokulabirako',
    'ntandika ntya',
    'hatua',
    'eleza zaidi',
    'nipe mifano',
    'vipi kuhusu',
    'ninawezaje kuanza',
  };

  static const _topicHints = {
    'business',
    'entrepreneur',
    'customer',
    'profit',
    'sales',
    'market',
    'money',
    'saving',
    'savings',
    'budget',
    'mobile',
    'sacco',
    'farming',
    'agriculture',
    'crop',
    'crops',
    'soil',
    'pests',
    'health',
    'medical',
    'pregnancy',
    'nutrition',
    'job',
    'jobs',
    'career',
    'cv',
    'digital',
    'phone',
    'internet',
    'online',
    'community',
    'group',
    'safety',
    'stress',
    'biashara',
    'mjasiriamali',
    'faida',
    'fedha',
    'pesa',
    'akiba',
    'bajeti',
    'kilimo',
    'mazao',
    'udongo',
    'wadudu',
    'afya',
    'daktari',
    'ujauzito',
    'kazi',
    'ujuzi',
    'simu',
    'intaneti',
    'mtandaoni',
    'jamii',
    'kikundi',
    'usalama',
    'msongo',
    'obusubuzi',
    'bakasitoma',
    'magoba',
    'ensimbi',
    'ssente',
    'okutereka',
    'obulimi',
    'ebirime',
    'ettaka',
    'obuwuka',
    'obulamu',
    'omusawo',
    'olubuto',
    'emirimu',
    'obukugu',
    'ssimu',
    'yintaneeti',
    'mutimbagano',
    'ekibiina',
    'obukuumi',
    'situleesi',
  };

  static const _stopWords = {
    'a',
    'about',
    'again',
    'am',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'can',
    'do',
    'does',
    'for',
    'from',
    'have',
    'help',
    'how',
    'i',
    'in',
    'is',
    'it',
    'me',
    'my',
    'of',
    'on',
    'or',
    'please',
    'should',
    'that',
    'the',
    'this',
    'to',
    'want',
    'what',
    'when',
    'where',
    'with',
    'you',
    'your',
    'za',
    'ya',
    'na',
    'kwa',
    'ku',
    'ni',
    'nini',
    'nina',
    'nifanye',
    'jinsi',
    'gani',
    'au',
    'wa',
    'la',
    'cha',
    'vya',
    'katika',
    'kwenye',
    'nga',
    'oba',
    'era',
    'mu',
    'kuva',
    'ki',
    'kiki',
    'nze',
    'gwe',
    'okukola',
    'okufuna',
    'okuyamba',
    'tya',
  };
}
