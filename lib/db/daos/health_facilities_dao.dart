import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/health_facilities_table.dart';

part 'health_facilities_dao.g.dart';

@DriftAccessor(tables: [HealthFacilities])
class HealthFacilitiesDao extends DatabaseAccessor<AppDatabase>
    with _$HealthFacilitiesDaoMixin {
  HealthFacilitiesDao(super.db);

  Stream<List<HealthFacility>> watchFacilities() {
    return (select(
      healthFacilities,
    )..orderBy([(f) => OrderingTerm.desc(f.addedAt)])).watch();
  }

  Future<int> addFacility({
    required String name,
    required String type,
    String? address,
  }) {
    return into(healthFacilities).insert(
      HealthFacilitiesCompanion.insert(
        name: name,
        type: type,
        address: Value(address),
      ),
    );
  }
}
