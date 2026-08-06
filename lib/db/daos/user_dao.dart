import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  static const _singletonId = 1;

  /// Reactive — emits null before onboarding, then the row on every write.
  Stream<User?> watchUser() =>
      (select(users)..where((u) => u.id.equals(_singletonId)))
          .watchSingleOrNull();

  /// Upsert the single local user row. createdAt is intentionally omitted
  /// from the companion so the DB default only applies on first insert and
  /// is left untouched on subsequent updates.
  Future<void> saveUser({
    required String name,
    String? role,
    String? location,
    String? firebaseUid,
  }) {
    return into(users).insertOnConflictUpdate(
      UsersCompanion(
        id: const Value(_singletonId),
        name: Value(name),
        role: Value(role),
        location: Value(location),
        firebaseUid:
            firebaseUid != null ? Value(firebaseUid) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
