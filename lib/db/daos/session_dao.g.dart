// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<OticDatabase> {
  $SessionSummariesTable get sessionSummaries =>
      attachedDatabase.sessionSummaries;
  $TopicProgressTable get topicProgress => attachedDatabase.topicProgress;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$SessionSummariesTableTableManager get sessionSummaries =>
      $$SessionSummariesTableTableManager(
        _db.attachedDatabase,
        _db.sessionSummaries,
      );
  $$TopicProgressTableTableManager get topicProgress =>
      $$TopicProgressTableTableManager(_db.attachedDatabase, _db.topicProgress);
}
