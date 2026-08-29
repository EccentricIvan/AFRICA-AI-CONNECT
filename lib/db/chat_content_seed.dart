import 'dart:convert';

import 'package:flutter/services.dart';

import 'daos/chat_content_dao.dart';

/// Parses assets/offline/offline_chat.json's curated intents into the
/// ChatIntents/ChatPatterns/ChatResponseVariants tables — called once, the
/// first time this schema version's tables are created (a fresh install, or
/// an existing install migrating up to schema 6). The JSON's `fallbacks`
/// block is intentionally not seeded here — OfflineChatService still reads
/// that directly from the asset, since it's a fixed safety net, not curated
/// content meant to grow over time.
Future<void> seedChatContentFromAsset(ChatContentDao dao) async {
  final Map<String, dynamic> decoded;
  try {
    final raw = await rootBundle.loadString(
      'assets/offline/offline_chat.json',
    );
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) return;
    decoded = parsed;
  } catch (_) {
    // No seed data available — the app still works from the compiled-in
    // safe fallbacks, and a content-pack sync can populate this table once
    // the device is online.
    return;
  }

  final rawIntents = decoded['intents'];
  if (rawIntents is! List) return;

  for (final rawIntent in rawIntents) {
    if (rawIntent is! Map) continue;
    final intent = Map<String, dynamic>.from(rawIntent);
    final id = intent['id']?.toString();
    if (id == null || id.isEmpty) continue;

    final source = intent['source'];
    final patterns = intent['patterns'];
    final responses = intent['responses'];

    final patternsByLocale = <String, List<String>>{};
    if (patterns is Map) {
      for (final entry in patterns.entries) {
        if (entry.value is! List) continue;
        patternsByLocale[entry.key.toString()] = [
          for (final p in entry.value as List) p.toString(),
        ];
      }
    }

    final variantsByLocale = <String, List<String>>{};
    if (responses is Map) {
      for (final entry in responses.entries) {
        // offline_chat.json carries a `_translation_notice` string
        // alongside the real per-locale responses in this map — skip
        // anything that isn't an actual locale entry.
        if (entry.key.toString().startsWith('_')) continue;
        final text = entry.value?.toString().trim();
        if (text == null || text.isEmpty) continue;
        variantsByLocale[entry.key.toString()] = [text];
      }
    }

    await dao.upsertIntent(
      intentKey: id,
      category: intent['category']?.toString() ?? 'general',
      sourceTitle: source is Map ? source['title']?.toString() : null,
      sourceUrl: source is Map ? source['url']?.toString() : null,
      patternsByLocale: patternsByLocale,
      variantsByLocale: variantsByLocale,
    );
  }
}
