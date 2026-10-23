import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'topic_explanations.dart';

/// A stop-gap until the official curriculum database arrives: when a teacher
/// has switched it on and the device is online, a "What is …?" question that
/// no bundled lesson or pack covers is answered with the topic's Wikipedia
/// introduction and lead picture.
///
/// - On by default; a teacher can switch it off (Teachers screen). Nothing else
///   in the app depends on it, and with no connection it simply finds
///   nothing, so the app stays offline-first.
/// - Only Wikipedia's public text and pictures are fetched. The question is
///   the only thing sent; nothing about the learner leaves the device.
/// - The answer says plainly that it is not from the syllabus, and credits
///   Wikipedia (CC BY-SA).
/// - Topics outside schoolwork (films, songs, people in sport or music…) are
///   refused.
class OnlineTopicLookup {
  OnlineTopicLookup({http.Client? client, this.timeout = const Duration(seconds: 20)})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final _cache = <String, TopicExplanation?>{};

  /// Found pictures and clips, per topic, for as long as the app runs: a
  /// class on one school connection asks Wikimedia once, not once per
  /// learner (it limits how often one address may ask).
  final _pictureCache = <String, List<WebPicture>>{};
  final _clipCache = <String, List<WebClip>>{};

  static const _headers = {
    'User-Agent': 'AIConnectAfrica/1.4 (offline school learning app)',
    'Accept': 'application/json',
  };

  /// Wikipedia descriptions of pages that are not schoolwork.
  static final _notSchoolwork = RegExp(
    r'\b(film|movie|song|album|single|band|singer|rapper|musician|actor|actress|'
    r'footballer|basketball|boxer|wrestler|video game|television|tv series|'
    r'soap opera|celebrity|pornograph|model and|youtuber|influencer)\b',
    caseSensitive: false,
  );

  /// The topic explanation for [message], or null when it asks for no topic,
  /// the topic isn't schoolwork, or the look-up fails.
  Future<TopicExplanation?> lookUp(String message) async {
    final topic = askedTopic(message);
    // "Where is it?": the chat's own topic, not a page called "It".
    if (topic == null || _onlyPointsBack.hasMatch(topic)) return null;
    if (_cache.containsKey(topic)) return _cache[topic];
    TopicExplanation? found;
    try {
      found = await _fetch(topic).timeout(timeout);
    } catch (e) {
      debugPrint('Online topic look-up failed: $e');
      return null; // Not cached: a dropped connection may come back.
    }
    _cache[topic] = found;
    return found;
  }

  Future<TopicExplanation?> _fetch(String topic) async {
    Future<Map<String, dynamic>?> summaryOf(String name) => _getJson(
          Uri.https('en.wikipedia.org', '/api/rest_v1/page/summary/${Uri.encodeComponent(name.replaceAll(' ', '_'))}', {'redirect': 'true'}),
        );
    var summary = await summaryOf(topic);
    // No page by that exact name ("president of uganda" is "President of
    // Uganda"): the best search match, when it shares a word with it.
    if (summary == null || summary['type'] != 'standard') {
      final found = await _searchTitle(topic);
      if (found == null) return null;
      summary = await summaryOf(found);
      if (summary == null || summary['type'] != 'standard') return null;
    }
    final description = summary['description'] as String? ?? '';
    if (_notSchoolwork.hasMatch(description)) return null;
    final title = summary['title'] as String? ?? topic;

    // The whole introduction, not just its first paragraph.
    final intro = await _getJson(
      Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'prop': 'extracts',
        'exintro': '1',
        'explaintext': '1',
        'redirects': '1',
        'titles': title,
      }),
    );
    final pages = (intro?['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?;
    final text = pages == null || pages.isEmpty
        ? summary['extract'] as String? ?? ''
        : (pages.values.first as Map<String, dynamic>)['extract'] as String? ?? '';
    final paragraphs = [
      for (final p in text.split('\n'))
        if (p.trim().length > 40) p.trim(),
    ];
    if (paragraphs.isEmpty) return null;

    final picture =
        ((summary['originalimage'] ?? summary['thumbnail']) as Map<String, dynamic>?)?['source'] as String?;
    final page =
        (((summary['content_urls'] as Map<String, dynamic>?)?['desktop'] as Map<String, dynamic>?)?['page']
            as String?) ??
        'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title)}';
    return TopicExplanation(
      id: 'online.${normalizeTopicText(title).replaceAll(' ', '_')}',
      subjectName: 'Online look-up',
      level: description.isEmpty ? 'general' : description,
      title: title,
      version: 0,
      aliases: [normalizeTopicText(topic), normalizeTopicText(title)],
      summary: paragraphs.first,
      sections: [
        if (paragraphs.length > 1)
          ExplanationSection(
            heading: 'More about $title',
            body: _clip(paragraphs.skip(1).take(4).join('\n\n'), 1800),
          ),
      ],
      diagram: picture,
      notes: [
        'From Wikipedia (online), not from your syllabus. Check it with your teacher.',
        'Text and picture: Wikipedia contributors, CC BY-SA 4.0 — $page',
      ],
    );
  }

  /// Topics whose Wikipedia pictures may not suit a school: no online
  /// pictures for these; the bundled diagrams answer instead.
  static final _onlyPointsBack =
      RegExp(r'^(it|its|this|that|they|them|these|those|he|she|him|her|there)$');

  static final _sensitiveTopic = RegExp(
    r'\b(sex|sexual|sexuality|nude|nudity|naked|genitals?|penis|vagina|vulva|'
    r'breasts?|porn\w*|erotic\w*|human body|anatomy|reproduction|reproductive|'
    r'puberty|intercourse|childbirth|pregnan\w*|condoms?|contracept\w*|drugs?|'
    r'weapons?|guns?|wars?|corpses?|death|kill\w*|murder\w*|suicide|torture|'
    r'execution|genocide)\b',
    caseSensitive: false,
  );

  static final _unsuitableFile = RegExp(
    r'(^|[\W_])(nude|nudity|naked|sex|sexual|genitals?|penis|vagina|vulva|breasts?|'
    r'porn\w*|erotic\w*|corpses?|dead|gore|wounds?)([\W_]|$)',
    caseSensitive: false,
  );

  /// Files that are page furniture, not pictures of the topic.
  static final _notAPicture = RegExp(
    r'(icon|logo|symbol|flag_of|commons-|wiki|edit-|question_book|ambox|'
    r'padlock|disambig|stub|portal|\.ogg$|\.ogv$|\.webm$|\.mp3$|\.pdf$|\.tif)',
    caseSensitive: false,
  );

  /// Up to [max] freely licensed pictures of [topic] from its Wikipedia
  /// article, the article's lead picture first, each with its credit. Empty
  /// when the topic isn't schoolwork, is sensitive, or the look-up fails.
  Future<List<WebPicture>> pictures(String topic, {int max = 4}) async {
    final name = topic.trim();
    if (name.isEmpty || _sensitiveTopic.hasMatch(name)) return const [];
    final key = '${name.toLowerCase()}|$max';
    final cached = _pictureCache[key];
    if (cached != null) return cached;
    try {
      final found = await _pictures(name, max).timeout(timeout);
      if (found.isNotEmpty) _pictureCache[key] = found;
      return found;
    } catch (e) {
      debugPrint('Online pictures failed: $e');
      return const [];
    }
  }

  Future<List<WebPicture>> _pictures(String topic, int max) async {
    Future<Map<String, dynamic>?> summaryOf(String name) => _getJson(
          Uri.https('en.wikipedia.org', '/api/rest_v1/page/summary/${Uri.encodeComponent(name.replaceAll(' ', '_'))}', {'redirect': 'true'}),
        );
    var summary = await summaryOf(topic);
    // No page by that exact name ("africa diverse cultures"): the best
    // search match ("Culture of Africa"), when it shares a word with it.
    if (summary == null || summary['type'] != 'standard') {
      final found = await _searchTitle(topic);
      if (found == null) return const [];
      summary = await summaryOf(found);
      if (summary == null || summary['type'] != 'standard') return const [];
    }
    final description = summary['description'] as String? ?? '';
    if (_notSchoolwork.hasMatch(description) || _sensitiveTopic.hasMatch(description)) {
      return const [];
    }
    final title = summary['title'] as String? ?? topic;
    final lead = ((summary['originalimage'] ?? summary['thumbnail']) as Map<String, dynamic>?)?['source'] as String?;
    // ".../thumb/6/62/Glass_frogs.jpg/960px-Glass_frogs.jpg?utm_source=…" →
    // "Glass_frogs.jpg"; an SVG's thumbnail adds ".png".
    final leadFile = lead == null
        ? null
        : Uri.decodeComponent(lead.split('?').first.split('/').lastWhere((p) => p.contains('.')))
              .replaceFirst(RegExp(r'^\d+px-'), '')
              .replaceFirst(RegExp(r'\.svg\.png$', caseSensitive: false), '.svg');
    // Pictures whose name or caption mentions the topic ("frog" in
    // "Glass_frogs"); the article's own lead picture always counts.
    final stems = {
      for (final w in topic.toLowerCase().split(RegExp(r'[^a-z]+')))
        if (w.length >= 3) w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w,
    };

    final data = await _getJson(
      Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'redirects': '1',
        'generator': 'images',
        'titles': title,
        'gimlimit': '50',
        'prop': 'imageinfo',
        'iiprop': 'url|mime|size|extmetadata',
        'iiurlwidth': '640',
      }),
    );
    final pages = ((data?['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?)?.values ?? const [];
    final found = <({WebPicture picture, bool isLead, int width})>[];
    for (final p in pages) {
      final page = p as Map<String, dynamic>;
      final file = (page['title'] as String? ?? '').replaceFirst('File:', '');
      final info = (page['imageinfo'] as List?)?.cast<Map<String, dynamic>>().firstOrNull;
      if (info == null || file.isEmpty) continue;
      if (_notAPicture.hasMatch(file) || _unsuitableFile.hasMatch(file)) continue;
      final mime = info['mime'] as String? ?? '';
      if (!RegExp(r'^image/(jpeg|png|svg\+xml|gif)$').hasMatch(mime)) continue;
      final width = info['width'] as int? ?? 0;
      if (width < 250) continue;
      final meta = info['extmetadata'] as Map<String, dynamic>? ?? const {};
      String field(String k) => ((meta[k] as Map<String, dynamic>?)?['value'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '‹')
          .replaceAll('&gt;', '›')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final license = field('LicenseShortName');
      if (!RegExp(r'public domain|cc0|cc by', caseSensitive: false).hasMatch(license) ||
          RegExp(r'\bnc\b|\bnd\b', caseSensitive: false).hasMatch(license)) {
        continue;
      }
      final url = info['thumburl'] as String? ?? info['url'] as String?;
      if (url == null) continue;
      final caption = field('ImageDescription');
      final artist = field('Artist');
      final isLead = leadFile != null && file.replaceAll(' ', '_') == leadFile.replaceAll(' ', '_');
      final named = '${file.toLowerCase()} ${caption.toLowerCase()}';
      if (!isLead && !stems.any(named.contains)) continue;
      found.add((
        picture: WebPicture(
          url: url,
          caption: caption.isEmpty
              ? file.replaceAll(RegExp(r'\.\w+$'), '').replaceAll('_', ' ')
              : (caption.length > 140 ? '${caption.substring(0, 139)}…' : caption),
          credit: '${artist.isEmpty ? 'Wikimedia Commons contributors' : artist}, $license, via Wikimedia Commons',
        ),
        isLead: isLead,
        width: width,
      ));
    }
    found.sort((a, b) => a.isLead != b.isLead ? (a.isLead ? -1 : 1) : b.width.compareTo(a.width));
    return [for (final f in found.take(max)) f.picture];
  }

  /// Up to [max] short, freely licensed video clips of [topic] from
  /// Wikimedia Commons, as small (about 480p) versions that load quickly on
  /// school internet. Same refusals as [pictures].
  Future<List<WebClip>> clips(String topic, {int max = 3}) async {
    final name = topic.trim();
    if (name.isEmpty || _sensitiveTopic.hasMatch(name)) return const [];
    final key = '${name.toLowerCase()}|$max';
    final cached = _clipCache[key];
    if (cached != null) return cached;
    try {
      final found = await _clips(name, max).timeout(timeout);
      if (found.isNotEmpty) _clipCache[key] = found;
      return found;
    } catch (e) {
      debugPrint('Online clips failed: $e');
      return const [];
    }
  }

  Future<List<WebClip>> _clips(String topic, int max) async {
    final data = await _getJson(
      Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'generator': 'search',
        'gsrnamespace': '6',
        'gsrsearch': '$topic filetype:video',
        'gsrlimit': '20',
        'prop': 'videoinfo',
        'viprop': 'url|mime|size|extmetadata|derivatives',
        'viurlwidth': '640',
      }),
    );
    final pages = [
      ...?((data?['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?)?.values,
    ];
    // Search order is relevance order.
    pages.sort((a, b) => ((a as Map)['index'] as int? ?? 0).compareTo((b as Map)['index'] as int? ?? 0));
    final stems = _stems(topic);
    final out = <WebClip>[];
    for (final p in pages) {
      final page = p as Map<String, dynamic>;
      final file = (page['title'] as String? ?? '').replaceFirst('File:', '');
      final info = (page['videoinfo'] as List?)?.cast<Map<String, dynamic>>().firstOrNull;
      if (info == null || file.isEmpty || _unsuitableFile.hasMatch(file)) continue;
      final duration = (info['duration'] as num?)?.toDouble() ?? 0;
      if (duration <= 0 || duration > 600) continue;
      final meta = info['extmetadata'] as Map<String, dynamic>? ?? const {};
      final license = _field(meta, 'LicenseShortName');
      if (!_freeLicense(license)) continue;
      final caption = _field(meta, 'ImageDescription');
      final named = '${file.toLowerCase()} ${caption.toLowerCase()}';
      if (!stems.any(named.contains) || _unsuitableFile.hasMatch(caption)) continue;
      // The smallest WebM at 360p or more; WebM plays in every WebView.
      final derivatives = [
        for (final d in (info['derivatives'] as List? ?? const []).cast<Map<String, dynamic>>())
          if ((d['type'] as String? ?? '').startsWith('video/webm') && (d['height'] as int? ?? 0) >= 360) d,
      ]..sort((a, b) => (a['height'] as int).compareTo(b['height'] as int));
      final src = derivatives.isEmpty
          ? ((info['size'] as int? ?? 1 << 30) < 25 * 1024 * 1024 ? info['url'] as String? : null)
          : derivatives.first['src'] as String?;
      if (src == null) continue;
      final artist = _field(meta, 'Artist');
      out.add(WebClip(
        url: src,
        poster: info['thumburl'] as String?,
        caption: caption.isEmpty
            ? file.replaceAll(RegExp(r'\.\w+$'), '').replaceAll('_', ' ')
            : (caption.length > 140 ? '${caption.substring(0, 139)}…' : caption),
        seconds: duration.round(),
        credit: '${artist.isEmpty ? 'Wikimedia Commons contributors' : artist}, $license, via Wikimedia Commons',
      ));
      if (out.length == max) break;
    }
    return out;
  }

  static Set<String> _stems(String topic) => {
    for (final w in topic.toLowerCase().split(RegExp(r'[^a-z]+')))
      if (w.length >= 3) w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w,
  };

  static bool _freeLicense(String license) =>
      RegExp(r'public domain|cc0|cc by', caseSensitive: false).hasMatch(license) &&
      !RegExp(r'\bnc\b|\bnd\b', caseSensitive: false).hasMatch(license);

  static String _field(Map<String, dynamic> meta, String k) =>
      ((meta[k] as Map<String, dynamic>?)?['value'] as String? ?? '')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&lt;', '‹')
          .replaceAll('&gt;', '›')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  /// The title of Wikipedia's best search match for [query], or null when
  /// there is none or it shares no word with [query].
  Future<String?> _searchTitle(String query) async {
    final data = await _getJson(
      Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'list': 'search',
        'srsearch': query,
        'srlimit': '1',
        'srprop': '',
      }),
    );
    final hits = (data?['query'] as Map<String, dynamic>?)?['search'] as List?;
    final title = (hits?.firstOrNull as Map<String, dynamic>?)?['title'] as String?;
    if (title == null) return null;
    final lower = title.toLowerCase();
    final shares = query.toLowerCase().split(RegExp(r'[^a-z]+')).any((w) =>
        w.length >= 4 && lower.contains(w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w));
    return shares ? title : null;
  }

  Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) return null;
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static String _clip(String text, int max) =>
      text.length > max ? '${text.substring(0, max).trimRight()}…' : text;
}

/// The chat reply to a picture request about [subject]: points to the
/// bundled diagram [local] (shown in the lesson card) and shows [web]
/// pictures inline, each credited. Says plainly when there is none.
String picturesReply(
  String subject, {
  TopicExplanation? local,
  List<WebPicture> web = const [],
  bool onlineAllowed = false,
  String from = 'Wikipedia',
}) {
  String clean(String s) => s.replaceAll(RegExp(r'[\[\]()*_`#<>]'), '').trim();
  if (local == null && web.isEmpty) {
    return onlineAllowed
        ? "I couldn't find a picture of **${clean(subject)}** right now. The "
              'device may be offline; try again when it is connected.'
        : "There's no picture of **${clean(subject)}** on this device yet. When "
              'the device is online, a teacher can switch on **Teachers → Look '
              "up topics online**, and I'll show real photos and diagrams.";
  }
  final b = StringBuffer();
  if (local != null) {
    b.writeln(
      'The diagram ${local.title.isEmpty ? '' : 'for **${clean(local.title)}** '}'
      'is shown above.',
    );
  }
  if (web.isNotEmpty) {
    if (b.isNotEmpty) b.writeln();
    b.writeln(
      'Here ${web.length == 1 ? 'is a picture' : 'are pictures'} of '
      '**${clean(subject)}** from $from:',
    );
    for (final p in web) {
      final url = p.url.replaceAll('(', '%28').replaceAll(')', '%29').replaceAll(' ', '%20');
      b
        ..writeln()
        ..writeln('![${clean(p.caption)}]($url)')
        ..writeln()
        ..writeln('_${clean(p.caption)}_ — ${clean(p.credit)}');
    }
  } else if (!onlineAllowed) {
    b
      ..writeln()
      ..writeln(
        'For real photos, a teacher can switch on **Teachers → Look up topics '
        'online** while the device is connected.',
      );
  }
  return b.toString().trim();
}

/// The chat reply to a request for clips of [subject]: each clip as its
/// poster picture, linked to the video (tapping it opens the clip player),
/// with its length and credit.
String clipsReply(String subject, List<WebClip> clips, {bool onlineAllowed = true}) {
  String clean(String s) => s.replaceAll(RegExp(r'[\[\]()*_`#<>]'), '').trim();
  String link(String url) => url.replaceAll('(', '%28').replaceAll(')', '%29').replaceAll(' ', '%20');
  if (clips.isEmpty) {
    return onlineAllowed
        ? "I couldn't find a video clip of **${clean(subject)}** right now. The "
              'device may be offline, or there may be no free clip of it. Try '
              'asking for pictures instead.'
        : 'Video clips come from the internet. When the device is online, a '
              'teacher can switch on **Teachers → Look up topics online**.';
  }
  final b = StringBuffer()
    ..writeln(
      'Here ${clips.length == 1 ? 'is a clip' : 'are clips'} of **${clean(subject)}**. '
      'Tap a clip to play it.',
    );
  for (final c in clips) {
    final time = '${c.seconds ~/ 60}:${(c.seconds % 60).toString().padLeft(2, '0')}';
    b.writeln();
    // The still, linked to the clip, then a text link: an easy tap target
    // on every screen size.
    if (c.poster != null) {
      b
        ..writeln('[![▶ ${clean(c.caption)}](${link(c.poster!)})](${link(c.url)})')
        ..writeln();
    }
    b.writeln('[▶ Watch: ${clean(c.caption)}](${link(c.url)}) ($time) — ${clean(c.credit)}');
  }
  return b.toString().trim();
}

/// A short, freely licensed video clip from Wikimedia Commons.
class WebClip {
  const WebClip({
    required this.url,
    required this.caption,
    required this.credit,
    required this.seconds,
    this.poster,
  });

  /// The video itself (a small WebM).
  final String url;

  /// A still from the clip, shown in the chat.
  final String? poster;
  final String caption;
  final String credit;
  final int seconds;
}

/// A freely licensed picture from Wikimedia Commons.
class WebPicture {
  const WebPicture({required this.url, required this.caption, required this.credit});

  final String url;
  final String caption;

  /// Author, licence and source: shown under the picture.
  final String credit;
}

/// Whether online look-ups (Wikipedia text, pictures and clips) are on. On by
/// default since 2026-10-21 (the user wants pictures and clips fetched); a
/// teacher can switch it off on the Teachers screen.
class OnlineTopicLookupSetting extends StateNotifier<bool> {
  OnlineTopicLookupSetting() : super(true) {
    _load();
  }

  /// A setting that stays [on] and is never read from or saved to the
  /// device (tests).
  OnlineTopicLookupSetting.fixed(bool on) : super(on);

  static const key = 'online_topic_lookup';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(key) ?? true;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, on);
    } catch (_) {}
  }
}

final onlineTopicLookupEnabledProvider =
    StateNotifierProvider<OnlineTopicLookupSetting, bool>(
      (ref) => OnlineTopicLookupSetting(),
    );

final onlineTopicLookupProvider = Provider<OnlineTopicLookup>(
  (ref) => OnlineTopicLookup(),
);
