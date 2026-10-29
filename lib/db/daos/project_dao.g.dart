// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dao.dart';

// ignore_for_file: type=lint
mixin _$ProjectDaoMixin on DatabaseAccessor<OticDatabase> {
  $StudentProjectsTable get studentProjects => attachedDatabase.studentProjects;
  ProjectDaoManager get managers => ProjectDaoManager(this);
}

class ProjectDaoManager {
  final _$ProjectDaoMixin _db;
  ProjectDaoManager(this._db);
  $$StudentProjectsTableTableManager get studentProjects =>
      $$StudentProjectsTableTableManager(
        _db.attachedDatabase,
        _db.studentProjects,
      );
}
