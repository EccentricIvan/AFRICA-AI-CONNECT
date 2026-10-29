import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/earned_badges_table.dart';

part 'badge_dao.g.dart';

@DriftAccessor(tables: [EarnedBadges])
class BadgeDao extends DatabaseAccessor<OticDatabase> with _$BadgeDaoMixin {
  BadgeDao(super.db);

  Future<List<EarnedBadge>> getBadgesForStudent(int studentId) =>
      (select(earnedBadges)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.earnedAt)]))
          .get();

  Future<bool> hasBadge(int studentId, String badgeId) async {
    final row = await (select(earnedBadges)
          ..where((t) =>
              t.studentId.equals(studentId) & t.badgeId.equals(badgeId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> awardBadge({
    required int studentId,
    required String badgeId,
    required String badgeName,
  }) async {
    await into(earnedBadges).insertOnConflictUpdate(
      EarnedBadgesCompanion.insert(
        studentId: studentId,
        badgeId: badgeId,
        badgeName: badgeName,
        earnedAt: Value(DateTime.now()),
      ),
    );
  }
}
