import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/mentors_table.dart';

part 'mentors_dao.g.dart';

@DriftAccessor(tables: [Mentors, MentorApplications])
class MentorsDao extends DatabaseAccessor<AppDatabase>
    with _$MentorsDaoMixin {
  MentorsDao(super.db);

  Stream<List<Mentor>> watchMentors() {
    return (select(mentors)..orderBy([(m) => OrderingTerm.asc(m.id)])).watch();
  }

  Future<int> seedMentor({
    required String name,
    required String expertise,
    required String location,
    required int yearsExp,
    required String colorKey,
  }) {
    return into(mentors).insert(
      MentorsCompanion.insert(
        name: name,
        expertise: expertise,
        location: location,
        yearsExp: yearsExp,
        colorKey: colorKey,
      ),
    );
  }

  Future<bool> hasAnyMentors() async =>
      (await (select(mentors)..limit(1)).get()).isNotEmpty;

  Future<int> apply({
    required String applicantName,
    required String expertise,
    String? message,
  }) {
    return into(mentorApplications).insert(
      MentorApplicationsCompanion.insert(
        applicantName: applicantName,
        expertise: expertise,
        message: Value(message),
      ),
    );
  }
}
