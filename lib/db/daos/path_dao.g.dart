// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_dao.dart';

// ignore_for_file: type=lint
mixin _$PathDaoMixin on DatabaseAccessor<OticDatabase> {
  $LearningPathsTable get learningPaths => attachedDatabase.learningPaths;
  PathDaoManager get managers => PathDaoManager(this);
}

class PathDaoManager {
  final _$PathDaoMixin _db;
  PathDaoManager(this._db);
  $$LearningPathsTableTableManager get learningPaths =>
      $$LearningPathsTableTableManager(_db.attachedDatabase, _db.learningPaths);
}
