import 'package:drift/drift.dart';

/// Persistent cache of AfriSLM translations.
///
/// Translation is by far the slowest step in a non-English turn — the GGUF
/// is reloaded per request by llm_llamacpp, so every call pays a full model
/// load before the first token. A hit here skips the model entirely, which
/// is the difference between an instant reply and a multi-second one.
///
/// This is not conversation history: only the text that was translated and
/// what it became, which is exactly what a repeat of the same string needs.
/// Rows are evicted least-recently-used past [kTranslationCacheMaxRows], so
/// the table stays small enough for a 32 GB device.
class TranslationCacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `sha256(modelTag|direction|langCode|normalizedSource)`, unique.
  /// Looked up directly — see TranslationCacheDao.lookup.
  TextColumn get cacheKey => text().unique()();

  /// BCP-47 code of the non-English side of the pair.
  TextColumn get langCode => text()();

  /// `to_en` or `from_en`.
  TextColumn get direction => text()();

  /// Identifies the model file that produced this row. Re-quantizing the
  /// GGUF (tools/quantize_translate_model.ps1 can emit Q4_K_M, Q4_0, …)
  /// changes what the model outputs, so entries from the previous file must
  /// not be served for the new one. Included in [cacheKey] rather than
  /// checked separately, so a model swap misses instead of matching.
  TextColumn get modelTag => text()();

  /// Kept in full so a hit can be verified against the key rather than
  /// trusted blindly — a hash collision would otherwise show the student
  /// someone else's sentence.
  TextColumn get sourceText => text()();
  TextColumn get translatedText => text()();

  IntColumn get useCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUsedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// LRU ceiling. A tutor reply is ~1 KB, so this caps the table at roughly
/// 4-6 MB — negligible next to the 641 MB model it saves reloading.
const kTranslationCacheMaxRows = 4000;
