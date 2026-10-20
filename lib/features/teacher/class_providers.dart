import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/device_registry.dart';
import '../../db/daos/class_group_dao.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import 'teacher_profiles.dart';
import 'teaching_scope.dart';

/// Every class/stream, alphabetical.
final classGroupsProvider = StreamProvider<List<ClassGroup>>((ref) {
  if (kIsWeb) return Stream.value(const []);
  return ref.watch(dbProvider).classGroupDao.watchAllClasses();
});

/// Every learner profile on this device, alphabetical.
final allLearnersProvider = StreamProvider<List<Student>>((ref) {
  if (kIsWeb) return Stream.value(const []);
  return ref.watch(dbProvider).studentDao.watchAllStudents();
});

/// Per-learner progress numbers, keyed by student id.
final learnerStatsProvider = StreamProvider<Map<int, LearnerStats>>((ref) {
  if (kIsWeb) return Stream.value(const {});
  return ref.watch(dbProvider).classGroupDao.watchLearnerStats();
});

/// This device's school and class-sync identity (null until first read).
final syncIdentityProvider = StreamProvider<SyncIdentityData?>((ref) {
  if (kIsWeb) return Stream.value(null);
  final dao = ref.watch(dbProvider).classSyncDao;
  // Make sure the row (and this device's signing key) exists.
  dao.identity();
  return dao.watchIdentity();
});

/// 'teacher', 'student', or null (undecided) — see `sync_identity`.
final deviceRoleProvider = StreamProvider<String?>((ref) {
  if (kIsWeb) return Stream.value('teacher');
  final dao = ref.watch(dbProvider).classSyncDao;
  dao.identity();
  return dao.watchDeviceRole();
});

/// Subjects the active learner says they take.
final enrolledSubjectsProvider = StreamProvider.family<Set<String>, int>((
  ref,
  studentId,
) {
  if (kIsWeb) return Stream.value(const {});
  return ref.watch(dbProvider).classSyncDao.watchEnrolled(studentId);
});

/// Subjects whose notes this learner may read — My subjects plus those
/// taught to their Admin enrolment's class.
final readableSubjectsProvider = StreamProvider.family<Set<String>, int>((
  ref,
  studentId,
) {
  if (kIsWeb) return Stream.value(const {});
  return ref.watch(dbProvider).classSyncDao.watchReadable(studentId);
});

/// Classes/streams the signed-in teacher is assigned to teach (the Admin's
/// teaching assignments) — the only ones they share notes with and sync.
final ownedClassesProvider = StreamProvider<List<ClassGroup>>((ref) async* {
  if (kIsWeb) {
    yield const [];
    return;
  }
  final mine = {
    for (final a in await ref.watch(myAssignmentsProvider.future))
      a.classGroupUuid,
  };
  yield* ref
      .watch(dbProvider)
      .classSyncDao
      .watchOwnedClasses()
      .map((all) => [for (final c in all) if (mine.contains(c.groupUuid)) c]);
});

/// The signed-in teacher's classes/streams, alphabetical.
final myClassGroupsProvider = ownedClassesProvider;

/// Classes/streams the signed-in teacher is the **Class Teacher** of — the
/// Admin assigned them the whole stream (`class_teacher_assignments`). A
/// class teacher is responsible for every learner registered to that stream,
/// across every subject, even subjects they do not personally teach.
final classTeacherGroupsProvider = StreamProvider<List<ClassGroup>>((
  ref,
) async* {
  if (kIsWeb) {
    yield const [];
    return;
  }
  final me = ref.watch(activeTeacherIdProvider);
  if (me == null) {
    yield const [];
    return;
  }
  final db = ref.watch(dbProvider);
  final mine = {
    for (final a
        in await (db.select(db.classTeacherAssignments)
              ..where((t) => t.teacherId.equals(me)))
            .get())
      a.classGroupUuid,
  };
  yield* db.classGroupDao.watchAllClasses().map(
    (all) => [
      for (final c in all)
        if (mine.contains(c.groupUuid)) c,
    ],
  );
});

/// The union of the classes the teacher teaches and the streams they are
/// Class Teacher of, sorted — the scope for viewing learner progress. Kept
/// as a plain function (not a provider) so each screen watches the two
/// underlying providers directly and updates the moment either resolves.
List<ClassGroup> visibleClassGroups(
  List<ClassGroup> taught,
  List<ClassGroup> asClassTeacher,
) {
  final byId = {for (final c in taught) c.id: c};
  for (final c in asClassTeacher) {
    byId[c.id] = c;
  }
  return byId.values.toList()
    ..sort((a, b) {
      final byClass = a.className.compareTo(b.className);
      return byClass != 0
          ? byClass
          : (a.streamName ?? '').compareTo(b.streamName ?? '');
    });
}

/// Root device: co-teachers of one class, by name.
final coTeachersProvider =
    StreamProvider.family<List<ClassCoTeacher>, String>((ref, classUuid) {
      if (kIsWeb) return Stream.value(const []);
      return ref.watch(dbProvider).coTeacherDao.watchCoTeachers(classUuid);
    });

/// Classes the signed-in teacher co-teaches (joined as co-teacher).
final delegatedClassesProvider = StreamProvider<List<CoTeachingClass>>((ref) {
  if (kIsWeb) return Stream.value(const []);
  final me = ref.watch(activeTeacherIdProvider);
  return ref
      .watch(dbProvider)
      .coTeacherDao
      .watchDelegatedClasses()
      .map((all) => [for (final c in all) if (c.ownerTeacherId == me) c]);
});

/// A delegated class's allocated subject ids.
Set<String> delegatedSubjects(CoTeachingClass c) {
  try {
    return {
      for (final s in jsonDecode(c.subjectIdsJson) as List)
        if (s is String) s,
    };
  } catch (_) {
    return const {};
  }
}

/// "S2 East" for a delegated class.
String delegatedClassLabel(CoTeachingClass c) {
  final stream = c.streamName?.trim() ?? '';
  return stream.isEmpty ? c.className : '${c.className} $stream';
}

/// For one subject: each note title → the classes it is shared with.
/// For a subject, per class: how many trusted devices hold the version
/// this device serves now.
final noteReachProvider = StreamProvider.family<Map<String, int>, String>((
  ref,
  subjectId,
) {
  if (kIsWeb) return Stream.value(const {});
  return DeviceRegistry(ref.watch(dbProvider)).watchReach(subjectId);
});

final noteSharesProvider =
    StreamProvider.family<Map<String, Set<String>>, String>((ref, subjectId) {
      if (kIsWeb) return Stream.value(const {});
      return ref
          .watch(dbProvider)
          .classSyncDao
          .watchSharesForSubject(subjectId);
    });

/// "S2 East", or just "S2" for a class with no streams.
String classLabel(ClassGroup group) {
  final stream = group.streamName?.trim() ?? '';
  return stream.isEmpty ? group.className : '${group.className} $stream';
}

/// Learners with no recorded study for this long are flagged to the teacher.
const kInactiveAfter = Duration(days: 7);

/// Average mastery (0–100) below which a learner who *has* studied is flagged.
const kLowMastery = 25;

/// Why a learner may need the teacher's attention, or null when they don't.
///
/// Deliberately two plain rules a teacher can check against the numbers on
/// screen — not a score.
String? needsHelpReason(Student learner, LearnerStats stats, DateTime now) {
  if (stats.topics == 0) return 'Not started';
  if (now.difference(learner.lastActiveAt) > kInactiveAfter) {
    return 'Inactive ${now.difference(learner.lastActiveAt).inDays} days';
  }
  if (stats.averageLevel < kLowMastery) return 'Low mastery';
  return null;
}
