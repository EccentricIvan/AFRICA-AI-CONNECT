import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/user_stats_table.dart';

part 'user_stats_dao.g.dart';

@DriftAccessor(tables: [UserStats, ActivityDays])
class UserStatsDao extends DatabaseAccessor<AppDatabase>
    with _$UserStatsDaoMixin {
  UserStatsDao(super.db);

  static const _singletonId = 1;

  Future<void> ensureRowExists() => into(userStats).insertOnConflictUpdate(
    UserStatsCompanion(updatedAt: Value(DateTime.now())),
  );

  Stream<UserStat> watchStats() =>
      (select(userStats)..where((s) => s.id.equals(_singletonId)))
          .watchSingle();

  Future<void> awardPoints(int amount) async {
    await ensureRowExists();
    final current = await (select(
      userStats,
    )..where((s) => s.id.equals(_singletonId))).getSingle();
    await (update(userStats)..where((s) => s.id.equals(_singletonId))).write(
      UserStatsCompanion(
        totalPoints: Value(current.totalPoints + amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Idempotent — records today once, then recomputes the consecutive-day
  /// streak by walking back from today. A gap of even one day resets the
  /// count to whatever runs from the most recent unbroken chain.
  Future<void> recordActivityToday() async {
    final todayKey = _dateKey(DateTime.now());
    final existing = await (select(
      activityDays,
    )..where((d) => d.id.equals(todayKey))).getSingleOrNull();
    if (existing == null) {
      await into(
        activityDays,
      ).insert(ActivityDaysCompanion.insert(id: todayKey));
    }
    await _recomputeStreak();
  }

  Future<void> _recomputeStreak() async {
    await ensureRowExists();
    var streak = 0;
    var day = DateTime.now();
    while (true) {
      final row = await (select(
        activityDays,
      )..where((d) => d.id.equals(_dateKey(day)))).getSingleOrNull();
      if (row == null) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    final current = await (select(
      userStats,
    )..where((s) => s.id.equals(_singletonId))).getSingle();
    final best = streak > current.bestStreakDays ? streak : current.bestStreakDays;
    await (update(userStats)..where((s) => s.id.equals(_singletonId))).write(
      UserStatsCompanion(
        currentStreakDays: Value(streak),
        bestStreakDays: Value(best),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
