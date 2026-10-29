// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website_dao.dart';

// ignore_for_file: type=lint
mixin _$WebsiteDaoMixin on DatabaseAccessor<OticDatabase> {
  $WebsiteProjectsTable get websiteProjects => attachedDatabase.websiteProjects;
  WebsiteDaoManager get managers => WebsiteDaoManager(this);
}

class WebsiteDaoManager {
  final _$WebsiteDaoMixin _db;
  WebsiteDaoManager(this._db);
  $$WebsiteProjectsTableTableManager get websiteProjects =>
      $$WebsiteProjectsTableTableManager(
        _db.attachedDatabase,
        _db.websiteProjects,
      );
}
