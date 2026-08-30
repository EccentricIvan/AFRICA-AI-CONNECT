import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/jobs_table.dart';

part 'jobs_dao.g.dart';

@DriftAccessor(tables: [Jobs, JobApplications])
class JobsDao extends DatabaseAccessor<AppDatabase> with _$JobsDaoMixin {
  JobsDao(super.db);

  Stream<List<Job>> watchJobs() {
    return (select(jobs)
          ..orderBy([(j) => OrderingTerm.desc(j.postedAt)]))
        .watch();
  }

  Stream<Job?> watchJob(int id) =>
      (select(jobs)..where((j) => j.id.equals(id))).watchSingleOrNull();

  Future<int> postJob({
    required String title,
    required String employer,
    required String type,
    required String colorKey,
    String? location,
    String? description,
    String? requirements,
    String? education,
    String? niceToHave,
  }) {
    return into(jobs).insert(
      JobsCompanion.insert(
        title: title,
        employer: employer,
        type: type,
        colorKey: colorKey,
        location: Value(location),
        description: Value(description),
        requirements: Value(requirements),
        education: Value(education),
        niceToHave: Value(niceToHave),
      ),
    );
  }

  /// Total applications the local user has submitted, across every job —
  /// feeds Profile's real achievements.
  Stream<int> watchMyApplicationsCount() {
    return select(jobApplications).watch().map((rows) => rows.length);
  }

  /// Reactive — null until the local user has applied to this job.
  Stream<JobApplication?> watchMyApplication(int jobId) {
    return (select(jobApplications)
          ..where((a) => a.jobId.equals(jobId))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> apply({
    required int jobId,
    required String applicantName,
    String? coverNote,
  }) {
    return into(jobApplications).insert(
      JobApplicationsCompanion.insert(
        jobId: jobId,
        applicantName: applicantName,
        coverNote: Value(coverNote),
      ),
    );
  }
}
