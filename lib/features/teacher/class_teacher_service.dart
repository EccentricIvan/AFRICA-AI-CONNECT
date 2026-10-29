import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/sync_ids.dart';
import '../../core/policy/policy.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../services/audit/audit_log.dart';
import 'teaching_scope.dart';

/// A learner a Class Teacher registered, and whether the Admin has it.
typedef RegisteredLearner = ({
  int studentId,
  String name,
  String classGroupUuid,
  bool withAdmin,
});

/// What a Class Teacher does: register new learners into the
/// classes/streams the Admin gave them — and nothing else. A registration
/// is made on the Class Teacher's own device and reaches the Admin's device
/// at the next Admin sync (`AdminRecords`), which carries it everywhere.
class ClassTeacherService {
  ClassTeacherService(this._db, this._policy);

  final OticDatabase _db;
  final Policy _policy;

  /// The classes/streams [teacherId] may register learners into.
  Future<List<ClassGroup>> classesOf(int? teacherId) async {
    final uuids = await TeachingScope(_db).classTeacherOf(teacherId);
    if (uuids.isEmpty) return const [];
    return (_db.select(_db.classGroups)
          ..where((t) => t.groupUuid.isIn(uuids))
          ..orderBy([
            (t) => OrderingTerm.asc(t.className),
            (t) => OrderingTerm.asc(t.streamName),
          ]))
        .get();
  }

  /// Registers [name] into [group] for [teacherId]. Null when done; else
  /// why not. Refused unless the Admin gave this teacher that class/stream.
  Future<String?> register({
    required int? teacherId,
    required String name,
    required ClassGroup group,
    int? academicYear,
  }) async {
    final trimmed = name.trim();
    final uuid = group.groupUuid;
    if (trimmed.isEmpty) return 'Enter the learner’s name.';
    if (teacherId == null || uuid == null) return 'Sign in first.';
    if (!await _policy.can(TeacherActor(teacherId), RegisterLearner(uuid))) {
      await AuditLogService(_db).record(
        'teacher:$teacherId',
        'refused.registration',
        detail: uuid,
      );
      return 'You can’t register learners into that class.';
    }
    final now = DateTime.now().toUtc();
    final enrolment = newSyncId();
    final studentId = await _db.transaction(() async {
      final id = await _db.studentDao.createStudent(
        StudentsCompanion.insert(name: trimmed, uuid: Value(newSyncId())),
      );
      await _db
          .into(_db.studentEnrolments)
          .insert(
            StudentEnrolmentsCompanion.insert(
              uuid: enrolment,
              studentId: id,
              classGroupUuid: uuid,
              academicYear: academicYear ?? now.year,
              createdAt: now.toIso8601String(),
            ),
          );
      await _db.classGroupDao.assignLearner(id, group.id);
      await _db
          .into(_db.learnerRegistrations)
          .insert(
            LearnerRegistrationsCompanion.insert(
              studentId: id,
              teacherId: teacherId,
              classGroupUuid: uuid,
              enrolmentUuid: enrolment,
              createdAt: now.toIso8601String(),
            ),
          );
      return id;
    });
    await AuditLogService(_db).record(
      'teacher:$teacherId',
      'learner.registered',
      detail: 'learner:$studentId $uuid',
    );
    return null;
  }

  /// The learners [teacherId] registered on this device, newest first.
  /// Names and classes only — never grades or progress.
  Stream<List<RegisteredLearner>> watchRegistered(int teacherId) {
    final r = _db.learnerRegistrations, s = _db.students;
    final q =
        _db.select(r).join([innerJoin(s, s.id.equalsExp(r.studentId))])
          ..where(r.teacherId.equals(teacherId))
          ..orderBy([OrderingTerm.desc(r.id)]);
    return q.watch().map(
      (rows) => [
        for (final row in rows)
          (
            studentId: row.readTable(s).id,
            name: row.readTable(s).name,
            classGroupUuid: row.readTable(r).classGroupUuid,
            withAdmin: row.readTable(r).sentAt != null,
          ),
      ],
    );
  }
}

final classTeacherServiceProvider = Provider<ClassTeacherService>(
  (ref) =>
      ClassTeacherService(ref.watch(dbProvider), ref.watch(policyProvider)),
);
