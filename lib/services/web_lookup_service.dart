import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/l10n/app_strings.dart';

class WebLookupResult {
  const WebLookupResult({
    required this.snippet,
    required this.sourceName,
    required this.sourceUrl,
  });

  final String snippet;
  final String sourceName;
  final String sourceUrl;
}

/// Only reached when neither the curated knowledge base nor the SALT
/// corpus has anything for a query, and only attempted when the device is
/// online. Every source here returns real, already-published text
/// verbatim — nothing fetched here is ever rewritten, summarized, or
/// combined with anything else; the caller must show it labeled as an
/// unverified web result, not as a vetted app answer.
///
/// Coverage caveat, by design, not oversight: none of these three sources
/// have meaningful content in Acholi, Ateso, Runyankole, or Runyoro, and
/// only sparse content in Luganda — this tier mostly helps English/Swahili
/// queries. The curated knowledge base and SALT tiers remain the primary
/// answer sources for the other languages.
class WebLookupService {
  static const _timeout = Duration(seconds: 6);

  /// A specific, trusted SearXNG instance base URL (no trailing slash),
  /// e.g. "https://searx.example.org". Empty by default — defaulting to an
  /// arbitrary public instance is a reliability and trust risk, so this
  /// tier stays disabled until a specific instance is deliberately chosen
  /// and configured at build time via --dart-define=SEARXNG_URL=...
  static const _searxngBaseUrl = String.fromEnvironment('SEARXNG_URL');

  static const _wikipediaLanguage = <AppLocale, String>{
    AppLocale.en: 'en',
    AppLocale.sw: 'sw',
    AppLocale.lg: 'lg',
    AppLocale.rw: 'rw',
    // No dedicated Wikipedia edition exists for these — English is a more
    // useful result than an empty/near-empty local edition.
    AppLocale.nyn: 'en',
    AppLocale.nyo: 'en',
    AppLocale.ach: 'en',
    AppLocale.teo: 'en',
  };

  Future<WebLookupResult?> lookup(String query, AppLocale locale) async {
    final wikimedia = await _tryWikimedia(query, locale);
    if (wikimedia != null) return wikimedia;

    final duckDuckGo = await _tryDuckDuckGo(query);
    if (duckDuckGo != null) return duckDuckGo;

    return _trySearxng(query);
  }

  Future<WebLookupResult?> _tryWikimedia(
    String query,
    AppLocale locale,
  ) async {
    final lang = _wikipediaLanguage[locale] ?? 'en';
    try {
      final searchUri = Uri.https('$lang.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srlimit': '1',
        'format': 'json',
        'origin': '*',
      });
      final searchResponse = await http.get(searchUri).timeout(_timeout);
      if (searchResponse.statusCode != 200) return null;
      final searchBody = jsonDecode(searchResponse.body);
      final results = searchBody['query']?['search'];
      if (results is! List || results.isEmpty) return null;
      final title = results.first['title']?.toString();
      if (title == null || title.isEmpty) return null;

      final summaryUri = Uri.https(
        '$lang.wikipedia.org',
        '/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
      );
      final summaryResponse = await http.get(summaryUri).timeout(_timeout);
      if (summaryResponse.statusCode != 200) return null;
      final summaryBody = jsonDecode(summaryResponse.body);
      final extract = summaryBody['extract']?.toString().trim();
      final pageUrl = summaryBody['content_urls']?['desktop']?['page']
          ?.toString();
      if (extract == null || extract.isEmpty || pageUrl == null) return null;

      return WebLookupResult(
        snippet: extract,
        sourceName: 'Wikipedia',
        sourceUrl: pageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<WebLookupResult?> _tryDuckDuckGo(String query) async {
    try {
      final uri = Uri.https('api.duckduckgo.com', '/', {
        'q': query,
        'format': 'json',
        'no_html': '1',
        'skip_disambig': '1',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      final text = body['AbstractText']?.toString().trim();
      final url = body['AbstractURL']?.toString();
      if (text == null || text.isEmpty || url == null || url.isEmpty) {
        return null;
      }
      final source = body['AbstractSource']?.toString();
      return WebLookupResult(
        snippet: text,
        sourceName: (source != null && source.isNotEmpty)
            ? source
            : 'DuckDuckGo',
        sourceUrl: url,
      );
    } catch (_) {
      return null;
    }
  }

  Future<WebLookupResult?> _trySearxng(String query) async {
    if (_searxngBaseUrl.isEmpty) return null;
    try {
      final uri = Uri.parse(
        '$_searxngBaseUrl/search',
      ).replace(queryParameters: {'q': query, 'format': 'json'});
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      final results = body['results'];
      if (results is! List || results.isEmpty) return null;
      final first = results.first;
      final content = first['content']?.toString().trim();
      final url = first['url']?.toString();
      if (content == null || content.isEmpty || url == null) return null;
      return WebLookupResult(
        snippet: content,
        sourceName: first['engine']?.toString() ?? 'SearXNG',
        sourceUrl: url,
      );
    } catch (_) {
      return null;
    }
  }
}
