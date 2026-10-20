import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import 'teacher_profiles.dart';

/// What a teacher may do, from the Admin's teaching assignments: upload to
/// a subject they teach, change and share only the materials they
/// uploaded, and only into classes they teach that subject in. Checked
/// here, below the screens.
class TeachingScope {
  TeachingScope(this._db);

  final OticDatabase _db;

  Future<List<TeachingAssignment>> assignments(int teacherId) => (_db.select(
    _db.teachingAssignments,
  )..where((t) => t.teacherId.equals(teacherId))).get();

  Stream<List<TeachingAssignment>> watchAssignments(int teacherId) =>
      (_db.select(
        _db.teachingAssignments,
      )..where((t) => t.teacherId.equals(teacherId))).watch();

  /// Whether [teacherId] teaches [subjectId] — to [classGroupUuid] when
  /// given.
  Future<bool> teaches(
    int? teacherId,
    String subjectId, {
    String? classGroupUuid,
  }) async {
    if (teacherId == null) return false;
    return (await assignments(teacherId)).any(
      (a) =>
          a.subjectId == subjectId &&
          (classGroupUuid == null || a.classGroupUuid == classGroupUuid),
    );
  }

  /// Whether [teacherId] may upload to [subjectId]: they teach it, or they
  /// made it for themselves in Lesson materials ([TeacherSubjects]).
  Future<bool> mayUpload(int? teacherId, String subjectId) async {
    if (teacherId == null) return false;
    return await teaches(teacherId, subjectId) ||
        await ownsSubject(teacherId, subjectId);
  }

  Future<bool> ownsSubject(int teacherId, String subjectId) async =>
      await (_db.select(_db.teacherSubjects)
            ..where((t) => t.teacherId.equals(teacherId))
            ..where((t) => t.subjectId.equals(subjectId)))
          .getSingleOrNull() !=
      null;

  Stream<Set<String>> watchOwnSubjects(int teacherId) =>
      (_db.select(_db.teacherSubjects)
            ..where((t) => t.teacherId.equals(teacherId)))
          .watch()
          .map((rows) => {for (final r in rows) r.subjectId});

  Future<void> recordOwnSubject(int teacherId, String subjectId) => _db
      .into(_db.teacherSubjects)
      .insertOnConflictUpdate(
        TeacherSubjectsCompanion.insert(
          teacherId: teacherId,
          subjectId: subjectId,
          createdAt: DateTime.now().toUtc().toIso8601String(),
        ),
      );

  /// The classes/streams [teacherId] may register learners into, as a
  /// Class Teacher (`class_groups.group_uuid`).
  Future<Set<String>> classTeacherOf(int? teacherId) async {
    if (teacherId == null) return const {};
    return {
      for (final a in await (_db.select(
        _db.classTeacherAssignments,
      )..where((t) => t.teacherId.equals(teacherId))).get())
        a.classGroupUuid,
    };
  }

  Future<int?> ownerOf(String subjectId, String documentTitle) async =>
      (await (_db.select(_db.noteOwners)
                ..where((t) => t.subjectId.equals(subjectId))
                ..where((t) => t.documentTitle.equals(documentTitle)))
              .getSingleOrNull())
          ?.teacherId;

  /// Whether [teacherId] may change or remove a note: they teach its
  /// subject (or made it themselves) and uploaded it. A note nobody owns
  /// (its teacher was removed) is open to whoever teaches the subject.
  Future<bool> mayChangeNote(
    int? teacherId,
    String subjectId,
    String documentTitle,
  ) async {
    if (!await mayUpload(teacherId, subjectId)) return false;
    final owner = await ownerOf(subjectId, documentTitle);
    return owner == null || owner == teacherId;
  }

  /// Whether [teacherId] may share a note into [classGroupUuid]: they may
  /// change it and teach its subject to that class.
  Future<bool> mayShare(
    int? teacherId,
    String subjectId,
    String documentTitle,
    String classGroupUuid,
  ) async =>
      await mayChangeNote(teacherId, subjectId, documentTitle) &&
      await teaches(teacherId, subjectId, classGroupUuid: classGroupUuid);

  Future<void> recordOwner(
    String subjectId,
    String documentTitle,
    int teacherId,
  ) => _db
      .into(_db.noteOwners)
      .insertOnConflictUpdate(
        NoteOwnersCompanion.insert(
          subjectId: subjectId,
          documentTitle: documentTitle,
          teacherId: teacherId,
        ),
      );

  Future<void> forgetOwner(String subjectId, String documentTitle) =>
      (_db.delete(_db.noteOwners)
            ..where((t) => t.subjectId.equals(subjectId))
            ..where((t) => t.documentTitle.equals(documentTitle)))
          .go();

  /// Drops every class share no assignment covers any more: a note may go
  /// to a class only while its uploader (or, for a note nobody owns, some
  /// teacher) is assigned that subject in that class. Run whenever
  /// assignments change, so the next Sync stops serving the rest. Returns
  /// how many shares were dropped.
  Future<int> pruneShares() => _db.transaction(() async {
    final taught = {
      for (final a in await _db.select(_db.teachingAssignments).get())
        (a.teacherId, a.classGroupUuid, a.subjectId),
    };
    final anyTeacher = {for (final t in taught) (t.$2, t.$3)};
    final owners = {
      for (final o in await _db.select(_db.noteOwners).get())
        (o.subjectId, o.documentTitle): o.teacherId,
    };
    var dropped = 0;
    for (final s in await _db.select(_db.resourceShares).get()) {
      final owner = owners[(s.subjectId, s.documentTitle)];
      final allowed = owner == null
          ? anyTeacher.contains((s.classGroupUuid, s.subjectId))
          : taught.contains((owner, s.classGroupUuid, s.subjectId));
      if (allowed) continue;
      dropped += await (_db.delete(
        _db.resourceShares,
      )..where((t) => t.id.equals(s.id))).go();
    }
    return dropped;
  });

  /// Every note owner of [subjectId], by document title.
  Stream<Map<String, int>> watchOwners(String subjectId) =>
      (_db.select(_db.noteOwners)..where((t) => t.subjectId.equals(subjectId)))
          .watch()
          .map((rows) => {for (final r in rows) r.documentTitle: r.teacherId});
}

final teachingScopeProvider = Provider<TeachingScope>(
  (ref) => TeachingScope(ref.watch(dbProvider)),
);

/// The signed-in teacher's assignments, live.
final myAssignmentsProvider = StreamProvider<List<TeachingAssignment>>((ref) {
  final me = ref.watch(activeTeacherIdProvider);
  if (kIsWeb || me == null) return Stream.value(const []);
  return ref.watch(teachingScopeProvider).watchAssignments(me);
});

/// Subjects the signed-in teacher made for themselves, live.
final myOwnSubjectsProvider = StreamProvider<Set<String>>((ref) {
  final me = ref.watch(activeTeacherIdProvider);
  if (kIsWeb || me == null) return Stream.value(const {});
  return ref.watch(teachingScopeProvider).watchOwnSubjects(me);
});

/// Note owners of one subject, by document title.
final noteOwnersProvider = StreamProvider.family<Map<String, int>, String>((
  ref,
  subjectId,
) {
  if (kIsWeb) return Stream.value(const {});
  return ref.watch(teachingScopeProvider).watchOwners(subjectId);
});
