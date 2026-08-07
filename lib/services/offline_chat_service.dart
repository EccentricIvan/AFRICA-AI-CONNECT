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
