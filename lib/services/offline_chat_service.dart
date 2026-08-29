import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../core/l10n/app_strings.dart';
import '../db/daos/chat_content_dao.dart';

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
  OfflineChatService(this._contentDao);

  final ChatContentDao _contentDao;

  // Only the `fallbacks` block still comes from the JSON asset — the
  // curated intents/patterns/variants themselves live in
  // ChatIntents/ChatPatterns/ChatResponseVariants (see chat_content_seed.dart
  // for the one-time migration and ChatContentSyncService for how the DB
  // grows over time). Fallback text is a fixed safety net, not content
  // meant to grow, so it stays simple.
  Map<String, dynamic>? _knowledgeBase;

  // SALT (github.com/SunbirdAI/salt-data-archive, CC-BY-SA-4.0) is a general
  // parallel-sentence corpus, not curated Q&A — it is only consulted when
  // nothing in the curated database matched, and only covers en/lg/ach/teo/nyn
  // (Sunbird's text-all corpus has no Swahili, Runyoro or Kinyarwanda).
  // Loaded once and pre-normalized so a ~25k-row scan stays cheap on
  // low-spec devices at query time.
  List<List<String>>? _saltSentences;
  Map<String, int>? _saltColumns;
  List<String>? _saltNormalizedEnglish;
  List<Set<String>>? _saltEnglishTokens;

  // This final safety net is compiled into the application. It deliberately
  // contains no network, provider, or configuration language: even if the
  // downloadable/bundled knowledge file is damaged, the user still receives
  // useful guidance in the language they selected.
  static const _safeFallbacks = <AppLocale, String>{
    AppLocale.en:
        'Let us make this practical. Write down your goal, what you have available, and the first small action you can take today. For more specific guidance, mention whether your question is about business, saving, farming, health, digital safety, jobs, or wellbeing. For an emergency, contact a trusted local professional or emergency service now.',
    AppLocale.lg:
        'Ka tukifuule eky\'omugaso. Wandiika ekigendererwa kyo, by\'olina, n\'ekintu ekitono ky\'osobola okukola leero. Okufuna amagezi agasingawo, gamba oba ekibuuzo kikwata ku busubuzi, okutereka ensimbi, obulimi, obulamu, obukuumi ku yintaneeti, emirimu oba emirembe gy\'omutima. Bwe kiba kya mangu, tuukirira omukugu gwe weesiga oba ab\'obuyambi.',
    AppLocale.sw:
        'Tulifanye hili kwa vitendo. Andika lengo lako, vitu ulivyo navyo, na hatua ndogo ya kwanza unayoweza kuchukua leo. Ili kupata mwongozo maalum zaidi, sema kama swali linahusu biashara, akiba, kilimo, afya, usalama mtandaoni, kazi au ustawi. Ikiwa ni dharura, wasiliana na mtaalamu wa karibu unayemwamini au huduma za dharura sasa.',
    AppLocale.nyn:
        'Ka tukikore eky\'omugasho. Handika ekigyendererwa kyawe, ebi oine, n\'ekintu kikye eki orikubaasa kukora eri izooba. Ahabw\'obuhabuzi oburikukiraho, gamba yaaba ori kubuuza aha by\'obushuubuzi, okutereka esente, obuhingi, amagara, oburinzi aha mutimbagano, emirimo nari embeera y\'omutima. Kyaba kiri eky\'amangu, shaba obuyambi aha mukugu ou orikwesiga.',
    AppLocale.nyo:
        'Ka tukikole eky\'omugaso. Handika ekigendererwa kyawe, ebi oine, n\'ekintu kitaito eki osobora kukora hati. Kusobora kutunga obuhabuzi oburukukiraho, gamba obukiraaba nikikwata ha busuubuzi, kutereka sente, bulimi, bwomeezi, obulinzi ha mutimbagano, mirimo rundi obusinge bw\'omutima. Obukiraaba kiri ky\'amangu, ragira omukugu ow\'orukwesiga.',
    AppLocale.ach:
        'Wek wak man obed me tic. Co gin ma imito, jami ma itye kwede, ki gin matidi ma itwero cako kwede tin. Pi tam ma opore, nyut ka lapeny ni tye ikom cato wil, gwoko lim, pur, yotkom, ber bedo i intanet, tic onyo kuc me cwiny. Ka obedo peko me oyot, lwong ladit ma igeno onyo jo me kony.',
    AppLocale.teo:
        'Wek iswamaun na ajok. Camun nu ikoto, iboro lu ijai ka ikes, ka aswam na edit na ipedori acakar lolo. Naarai aijen na epite, ingit karai akiro nuek aduka, akoru esirigin, akoru, ajar, aijar ejok toma internet, aswam arai ayalama. Karai erai na apedor, ingarakina ekapolon lo ijenara.',
  };

  Future<void> _loadKnowledgeBase() async {
    if (_knowledgeBase != null) return;

    try {
      final decoded = jsonDecode(
        await rootBundle.loadString('assets/offline/offline_chat.json'),
      );
      _knowledgeBase =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      _knowledgeBase = <String, dynamic>{};
    }
  }

  Future<void> _loadSaltCorpus() async {
    if (_saltSentences != null) return;

    try {
      final decoded = jsonDecode(
        await rootBundle.loadString('assets/offline/salt_corpus.json'),
      );
      final columns = decoded is Map ? decoded['columns'] : null;
      final sentences = decoded is Map ? decoded['sentences'] : null;
      if (columns is List && sentences is List) {
        _saltColumns = {
          for (var i = 0; i < columns.length; i++) columns[i].toString(): i,
        };
        _saltSentences = [
          for (final row in sentences)
            if (row is List) [for (final cell in row) cell.toString()],
        ];
      }
    } catch (_) {
      // SALT is an enrichment layer — its absence must never break offline
      // chat, which still has the curated knowledge base and safe fallbacks.
    }

    _saltSentences ??= const [];
    _saltColumns ??= const {};
    _saltNormalizedEnglish = [
      for (final row in _saltSentences!) _normalize(row.isEmpty ? '' : row[0]),
    ];
    _saltEnglishTokens = [
      for (final normalized in _saltNormalizedEnglish!)
        _tokens(normalized, stemEnglish: true),
    ];
  }

  // Curated intents score above 220 on a decent multi-word match. SALT rows
  // are generic sentences, not authored answers, so a much higher bar is
  // used: this only fires on a near-exact or strong phrase match, i.e. the
  // user's wording is genuinely close to a known sentence worth translating.
  static const _saltMinScore = 500;

  Future<OfflineChatMatch?> _findSaltMatch(
    String normalizedMessage,
    AppLocale locale,
  ) async {
    // Matching is always scored against the English column, so an English
    // locale would just echo back an unrelated English sentence — no
    // translation is happening, so there is nothing useful to return.
    if (locale == AppLocale.en) return null;

    await _loadSaltCorpus();
    final columnIndex = _saltColumns?[locale.name];
    final sentences = _saltSentences;
    final normalizedEnglish = _saltNormalizedEnglish;
    final englishTokens = _saltEnglishTokens;
    if (columnIndex == null ||
        sentences == null ||
        normalizedEnglish == null ||
        englishTokens == null ||
        sentences.isEmpty) {
      return null;
    }

    final queryTokens = _tokens(normalizedMessage, stemEnglish: true);
    var bestScore = 0;
    List<String>? bestRow;
    for (var i = 0; i < sentences.length; i++) {
      final row = sentences[i];
      if (row.length <= columnIndex) continue;

      final candidate = normalizedEnglish[i];
      if (candidate.isEmpty) continue;

      int score;
      if (normalizedMessage == candidate) {
        score = 1200 + candidate.length;
      } else if (normalizedMessage.contains(candidate) ||
          candidate.contains(normalizedMessage)) {
        score = 500 + math.min(normalizedMessage.length, candidate.length);
      } else {
        final common = queryTokens.intersection(englishTokens[i]).length;
        if (common == 0) continue;
        final coverage = common / queryTokens.length;
        final precision = common / englishTokens[i].length;
        score = (coverage * 240 + precision * 100 + common * 25).round();
      }

      if (score > bestScore) {
        bestScore = score;
        bestRow = row;
      }
    }

    if (bestRow == null || bestScore < _saltMinScore) return null;
    return OfflineChatMatch(
      reply: bestRow[columnIndex],
      intentId: 'salt',
      category: 'translation',
      score: bestScore,
      sourceTitle: 'Sunbird AI SALT dataset',
      sourceUrl: 'https://github.com/SunbirdAI/salt-data-archive',
    );
  }

  String _normalize(String text) =>
      text
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  // Deliberately English-only and conservative — stripping "-s"/"-ing"/"-ed"
  // does not correspond to real morphology in Bantu languages like Luganda
  // or Swahili (which pluralize/inflect via prefixes, not suffixes) or in
  // Nilotic languages like Acholi/Ateso, so applying this to non-English
  // tokens would risk coincidental false matches, not just miss real ones.
  // Only ever called where the text being tokenized is known to be
  // English: curated patterns/messages when locale is English, and the
  // SALT tier, which always scores against its English column regardless
  // of the user's selected locale.
  String _stemEnglish(String token) {
    if (token.length <= 3) return token;
    if (token.endsWith('ing') && token.length > 5) {
      return token.substring(0, token.length - 3);
    }
    if (token.endsWith('ed') && token.length > 4) {
      return token.substring(0, token.length - 2);
    }
    if (token.endsWith('es') && token.length > 4) {
      return token.substring(0, token.length - 2);
    }
    if (token.endsWith('s') && !token.endsWith('ss') && token.length > 3) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  Set<String> _tokens(String text, {bool stemEnglish = false}) => _normalize(
    text,
  ).split(' ').where((token) => token.length > 1).map((token) {
    return stemEnglish ? _stemEnglish(token) : token;
  }).toSet();

  int _score(String message, String candidate, {bool stemEnglish = false}) {
    final normalizedCandidate = _normalize(candidate);
    if (normalizedCandidate.isEmpty) return 0;
    if (message == normalizedCandidate) return 1200 + candidate.length;
    if (message.contains(normalizedCandidate) ||
        normalizedCandidate.contains(message)) {
      return 500 + math.min(message.length, normalizedCandidate.length);
    }

    final queryTokens = _tokens(message, stemEnglish: stemEnglish);
    final candidateTokens = _tokens(
      normalizedCandidate,
      stemEnglish: stemEnglish,
    );
    if (queryTokens.isEmpty || candidateTokens.isEmpty) return 0;
    final common = queryTokens.intersection(candidateTokens).length;
    if (common == 0) return 0;

    final coverage = common / queryTokens.length;
    final precision = common / candidateTokens.length;
    return (coverage * 240 + precision * 100 + common * 25).round();
  }

  /// Finds the best curated answer for [message], falling back to the SALT
  /// translation-lookup tier when nothing curated matches.
  ///
  /// [priorCategory] — the previous turn's matched intent category, if any
  /// — nudges an *ambiguous* match (220-350) toward the same topic as the
  /// conversation was just on. This only changes which existing answer gets
  /// picked among near-ties; it never generates or alters any text.
  Future<OfflineChatMatch?> findMatch(
    String message,
    AppLocale locale, {
    String? priorCategory,
  }) async {
    final normalizedMessage = _normalize(message);
    if (normalizedMessage.isEmpty) return null;

    final patterns = await _contentDao.patternsForLocale(locale.name);
    final patternsByIntent = <String, List<String>>{};
    for (final row in patterns) {
      (patternsByIntent[row.intentKey] ??= []).add(row.pattern);
    }

    final stemEnglish = locale == AppLocale.en;
    String? bestIntentKey;
    var bestScore = 0;
    for (final entry in patternsByIntent.entries) {
      var intentScore = 0;
      for (final pattern in entry.value) {
        intentScore = math.max(
          intentScore,
          _score(normalizedMessage, pattern, stemEnglish: stemEnglish),
        );
      }
      if (intentScore < 220) continue;

      var adjustedScore = intentScore;
      if (priorCategory != null && intentScore < 350) {
        final intent = await _contentDao.intentByKey(entry.key);
        if (intent?.category == priorCategory) adjustedScore += 50;
      }

      if (adjustedScore > bestScore) {
        bestScore = adjustedScore;
        bestIntentKey = entry.key;
      }
    }

    if (bestIntentKey != null) {
      final intent = await _contentDao.intentByKey(bestIntentKey);
      final reply = await _contentDao.pickVariant(bestIntentKey, locale.name);
      if (intent != null && reply != null) {
        return OfflineChatMatch(
          reply: reply,
          intentId: bestIntentKey,
          category: intent.category,
          score: bestScore,
          sourceTitle: intent.sourceTitle,
          sourceUrl: intent.sourceUrl,
        );
      }
    }

    return _findSaltMatch(normalizedMessage, locale);
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

  Future<String> getGuidance(String message, AppLocale locale) async {
    try {
      final match = await findMatch(message, locale);
      if (match != null) return match.reply;
      return await getFallback(locale) ?? _safeFallbacks[locale]!;
    } catch (_) {
      return _safeFallbacks[locale]!;
    }
  }
}
