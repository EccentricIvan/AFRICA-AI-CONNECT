// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$TranslationCacheDaoMixin on DatabaseAccessor<OticDatabase> {
  $TranslationCacheEntriesTable get translationCacheEntries =>
      attachedDatabase.translationCacheEntries;
  TranslationCacheDaoManager get managers => TranslationCacheDaoManager(this);
}

class TranslationCacheDaoManager {
  final _$TranslationCacheDaoMixin _db;
  TranslationCacheDaoManager(this._db);
  $$TranslationCacheEntriesTableTableManager get translationCacheEntries =>
      $$TranslationCacheEntriesTableTableManager(
        _db.attachedDatabase,
        _db.translationCacheEntries,
      );
}
