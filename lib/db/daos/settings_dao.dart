import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const _singletonId = 1;

  /// Creates the defaults row if it doesn't exist yet; a harmless
  /// timestamp-only update otherwise, so existing toggle values are never
  /// clobbered. Called once at app startup (see settingsBootstrapProvider).
  /// `updatedAt` must be included even on the no-op path — SQLite rejects
  /// an `ON CONFLICT DO UPDATE SET` with an empty column list, which is
  /// what an all-absent companion would otherwise generate.
  Future<void> ensureRowExists() => into(settings).insertOnConflictUpdate(
    SettingsCompanion(updatedAt: Value(DateTime.now())),
  );

  /// Reactive — the row is guaranteed to exist by the time this is watched
  /// in practice (ensureRowExists runs at startup), so watchSingle is safe.
  Stream<Setting> watchSettings() =>
      (select(settings)..where((s) => s.id.equals(_singletonId)))
          .watchSingle();

  Future<void> setAutoSync(bool value) =>
      _update(SettingsCompanion(autoSyncEnabled: Value(value)));

  Future<void> setPushNotifications(bool value) =>
      _update(SettingsCompanion(pushNotificationsEnabled: Value(value)));

  Future<void> setCommunityUpdates(bool value) =>
      _update(SettingsCompanion(communityUpdatesEnabled: Value(value)));

  Future<void> _update(SettingsCompanion companion) async {
    await ensureRowExists();
    await (update(
      settings,
    )..where((s) => s.id.equals(_singletonId))).write(
      companion.copyWith(updatedAt: Value(DateTime.now())),
    );
  }
}
