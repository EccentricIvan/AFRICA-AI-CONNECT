import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/translation_cache_table.dart';

part 'translation_cache_dao.g.dart';

/// Read/write access to the persistent translation cache.
///
/// Every method swallows its own errors at the call site in
/// [TranslationPipeline] — a cache is an optimization, and a broken one must
/// degrade to "translate again", never to a failed turn.
@DriftAccessor(tables: [TranslationCacheEntries])
class TranslationCacheDao extends DatabaseAccessor<OticDatabase>
    with _$TranslationCacheDaoMixin {
  TranslationCacheDao(super.db);

  /// Returns the cached translation for [cacheKey], or null.
  ///
  /// [expectedSource] guards against a hash collision serving the wrong
  /// sentence: the stored source must match what the caller actually asked
  /// for. A mismatch is treated as a miss, not as a hit.
  Future<String?> lookup(String cacheKey, String expectedSource) async {
    final row = await (select(translationCacheEntries)
          ..where((t) => t.cacheKey.equals(cacheKey))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    if (row.sourceText != expectedSource) return null;

    // Fire-and-forget LRU bookkeeping: a hit must not wait on a write.
    unawaited(_touch(row.id));
    return row.translatedText;
  }

  /// LRU bookkeeping for a hit. One statement, not two: this runs on the
  /// fast path and its only job is to keep [prune] evicting the right rows.
  Future<void> _touch(int id) async {
    try {
      await customUpdate(
        'UPDATE translation_cache_entries '
        'SET use_count = use_count + 1, last_used_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Variable.withInt(id),
        ],
        updates: {translationCacheEntries},
      );
    } catch (_) {
      // Bookkeeping only — never surface.
    }
  }

  /// Stores a verified translation, replacing any existing row for the key.
  Future<void> store({
    required String cacheKey,
    required String langCode,
    required String direction,
    required String modelTag,
    required String sourceText,
    required String translatedText,
  }) async {
    await into(translationCacheEntries).insertOnConflictUpdate(
      TranslationCacheEntriesCompanion.insert(
        cacheKey: cacheKey,
        langCode: langCode,
        direction: direction,
        modelTag: modelTag,
        sourceText: sourceText,
        translatedText: translatedText,
        lastUsedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> countEntries() async {
    final count = translationCacheEntries.id.count();
    final row = await (selectOnly(translationCacheEntries)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Drops the least recently used rows until at most [maxRows] remain.
  Future<void> prune({int maxRows = kTranslationCacheMaxRows}) async {
    final total = await countEntries();
    if (total <= maxRows) return;
    await customUpdate(
      'DELETE FROM translation_cache_entries WHERE id IN ('
      '  SELECT id FROM translation_cache_entries'
      '  ORDER BY last_used_at ASC, id ASC LIMIT ?'
      ')',
      variables: [Variable.withInt(total - maxRows)],
      updates: {translationCacheEntries},
    );
  }

  /// Wipes the cache — used when the student clears local data.
  Future<void> clear() => delete(translationCacheEntries).go();
}

/// Local `unawaited` so this file doesn't depend on dart:async elsewhere.
void unawaited(Future<void> future) {
  future.catchError((Object _) {});
}
