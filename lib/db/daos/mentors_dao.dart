import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/mentors_table.dart';

part 'mentors_dao.g.dart';

@DriftAccessor(tables: [Mentors])
class MentorsDao extends DatabaseAccessor<AppDatabase>
    with _$MentorsDaoMixin {
  MentorsDao(super.db);

  Stream<List<Mentor>> watchMentors() {
    return (select(mentors)..orderBy([(m) => OrderingTerm.asc(m.id)])).watch();
  }

  /// Becoming a mentor is immediate — no application/approval step. The
  /// caller (mentorship_screen.dart) also creates and joins the paired
  /// Group for this mentor's circle right after this succeeds.
  Future<int> createMentor({
    required String name,
    required String expertise,
    required String location,
    required int yearsExp,
    required String colorKey,
    String? bio,
  }) {
    return into(mentors).insert(
      MentorsCompanion.insert(
        name: name,
        expertise: expertise,
        location: location,
        yearsExp: yearsExp,
        colorKey: colorKey,
        bio: Value(bio),
      ),
    );
  }
}
