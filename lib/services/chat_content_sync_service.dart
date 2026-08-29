import 'package:cloud_firestore/cloud_firestore.dart';

import '../db/daos/chat_content_dao.dart';

/// Periodically grows the curated chat knowledge base from a shared,
/// admin-authored Firestore document — the app's only live backend, per
/// CLAUDE.md. Checked once per app launch (see main.dart); any failure
/// (offline, timeout, permission, malformed document) is caught and
/// ignored, so the app just keeps using whatever curated content it
/// already has locally. There is no review/admin UI for this yet — the
/// document is authored manually (Firebase console or a script) until
/// that lands.
class ChatContentSyncService {
  ChatContentSyncService(this._contentDao);

  final ChatContentDao _contentDao;

  static const _timeout = Duration(seconds: 8);

  Future<void> sync() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_content')
          .doc('current')
          .get()
          .timeout(_timeout);

      final data = snapshot.data();
      if (data == null) return;

      final remoteVersion = data['version'];
      if (remoteVersion is! int) return;

      final appliedVersion = await _contentDao.appliedContentVersion();
      if (remoteVersion <= appliedVersion) return;

      final rawIntents = data['intents'];
      if (rawIntents is! List) return;

      for (final rawIntent in rawIntents) {
        if (rawIntent is! Map) continue;
        final intent = Map<String, dynamic>.from(rawIntent);
        final id = intent['id']?.toString();
        if (id == null || id.isEmpty) continue;

        await _contentDao.upsertIntent(
          intentKey: id,
          category: intent['category']?.toString() ?? 'general',
          sourceTitle: intent['sourceTitle']?.toString(),
          sourceUrl: intent['sourceUrl']?.toString(),
          patternsByLocale: _stringListMap(intent['patterns']),
          variantsByLocale: _stringListMap(intent['responses']),
        );
      }

      await _contentDao.setAppliedContentVersion(remoteVersion);
    } catch (_) {
      // Offline, permission-denied, malformed document, or any other
      // failure — the app is designed to work fully from its existing
      // local content, so this is never surfaced to the user.
    }
  }

  Map<String, List<String>> _stringListMap(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, List<String>>{};
    for (final entry in raw.entries) {
      if (entry.value is! List) continue;
      result[entry.key.toString()] = [
        for (final v in entry.value as List) v.toString(),
      ];
    }
    return result;
  }
}
