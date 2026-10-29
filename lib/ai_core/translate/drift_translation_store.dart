import '../../db/otic_database.dart';
import '../../db/tables/translation_cache_table.dart';
import 'translation_pipeline.dart';

/// [TranslationStore] backed by the local SQLite database.
///
/// Kept out of translation_pipeline.dart so the pipeline itself never
/// depends on drift — that is what lets the pipeline's tests run without a
/// database, and what guarantees a broken cache cannot break a translation.
///
/// Pruning is amortized rather than run on every write: counting rows on
/// each save would add a query to the hot path for no benefit, since the
/// ceiling is a soft one.
class DriftTranslationStore implements TranslationStore {
  DriftTranslationStore(this._db);

  final OticDatabase _db;

  /// Writes since the last prune. The cache only grows on a cache *miss*,
  /// which already cost a full model load, so this counter moves slowly.
  int _writesSincePrune = 0;

  /// How many saves between prunes. 200 rows of overshoot past
  /// [kTranslationCacheMaxRows] is a few hundred KB.
  static const _pruneEvery = 200;

  @override
  Future<String?> lookup(String cacheKey, String expectedSource) {
    return _db.translationCacheDao.lookup(cacheKey, expectedSource);
  }

  @override
  Future<void> save({
    required String cacheKey,
    required String langCode,
    required String direction,
    required String modelTag,
    required String sourceText,
    required String translatedText,
  }) async {
    await _db.translationCacheDao.store(
      cacheKey: cacheKey,
      langCode: langCode,
      direction: direction,
      modelTag: modelTag,
      sourceText: sourceText,
      translatedText: translatedText,
    );
    if (++_writesSincePrune >= _pruneEvery) {
      _writesSincePrune = 0;
      await _db.translationCacheDao.prune(maxRows: kTranslationCacheMaxRows);
    }
  }
}
