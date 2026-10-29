// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_dao.dart';

// ignore_for_file: type=lint
mixin _$BadgeDaoMixin on DatabaseAccessor<OticDatabase> {
  $EarnedBadgesTable get earnedBadges => attachedDatabase.earnedBadges;
  BadgeDaoManager get managers => BadgeDaoManager(this);
}

class BadgeDaoManager {
  final _$BadgeDaoMixin _db;
  BadgeDaoManager(this._db);
  $$EarnedBadgesTableTableManager get earnedBadges =>
      $$EarnedBadgesTableTableManager(_db.attachedDatabase, _db.earnedBadges);
}
