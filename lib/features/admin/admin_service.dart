import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/sync_ids.dart';
import '../../collaboration/sync/device_registry.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../services/audit/audit_log.dart';
import '../../services/custom_subject_service.dart';
import '../../services/learner_data_wiper.dart';
import '../../services/offline_storage_service.dart';
import '../teacher/teacher_pin.dart';
import '../teacher/teacher_profiles.dart' show kSessionLife;
import '../teacher/teaching_scope.dart';

/// Proof that the Admin signed in with their PIN. Only [AdminService] makes
/// one, and every change to the school's records needs it — the rule is
/// enforced here, below the screens.
class AdminSession {
  AdminSession._(this.name);
  final String name;
}

/// The school's one Admin and the records only they change: teachers,
/// classes and streams, subjects, teaching assignments, learners and their
/// enrolments.
///
/// Like the other PINs, the Admin PIN keeps people apart on a shared
/// device; it is not real security.
class AdminService {
  AdminService(this._db, this._subjects, this._wiper)
    : _audit = AuditLogService(_db);

  final OticDatabase _db;
  final CustomSubjectService _subjects;
  final LearnerDataWiper _wiper;
  final AuditLogService _audit;

  /// Records an Admin action in the device's audit log: names and ids
  /// only, never a PIN.
  Future<void> _log(String action, [String detail = '']) =>
      _audit.record('admin', action, detail: detail);

  Future<AdminIdentityRow?> _row() => (_db.select(
    _db.adminIdentity,
  )..where((t) => t.id.equals(1))).getSingleOrNull();

  Future<bool> isSetUp() async => await _row() != null;

  /// Sets up this device's Admin. Refused once one exists, and on a device
  /// that holds another Admin's school records: a school has one Admin,
  /// who takes over there with their passphrase instead.
  Future<AdminSession?> setUp({
    required String name,
    required String pin,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !TeacherPin.isValidFormat(pin)) return null;
    if (await isSetUp()) return null;
    if (await (_db.select(
          _db.adminRecordsState,
        )..where((t) => t.id.equals(1))).getSingleOrNull() !=
        null) {
      return null;
    }
    final salt = newPinSalt();
    await _db
        .into(_db.adminIdentity)
        .insert(
          AdminIdentityCompanion.insert(
            id: const Value(1),
            name: trimmed,
            pinSalt: salt,
            pinHash: await hashPinStrong(salt, pin),
            pinPlain: Value(pin),
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
    await _log('admin.set_up', trimmed);
    return AdminSession._(trimmed);
  }

  /// The Admin's PIN in the clear, for a signed-in Admin to note down; null
  /// for an Admin set up before it was stored.
  Future<String?> pin() async => (await _row())?.pinPlain;

  /// Sets a new Admin PIN when the current one is forgotten, keeping every
  /// record. Recovery only — the sign-in screen offers it. False when no
  /// Admin exists or the new PIN is malformed.
  Future<bool> recoverPin(String next) async {
    if (!TeacherPin.isValidFormat(next)) return false;
    final row = await _row();
    if (row == null) return false;
    final salt = newPinSalt();
    await (_db.update(_db.adminIdentity)..where((t) => t.id.equals(1))).write(
      AdminIdentityCompanion(
        pinSalt: Value(salt),
        pinHash: Value(await hashPinStrong(salt, next)),
        pinPlain: Value(next),
      ),
    );
    await _log('admin.pin_recovered');
    return true;
  }

  Future<AdminSession?> signIn(String pin) async {
    final row = await _row();
    if (row == null || !await pinMatches(row.pinSalt, pin, row.pinHash)) {
      if (row != null) await _log('refused.admin_pin');
      return null;
    }
    if (pinNeedsUpgrade(row.pinHash)) {
      await (_db.update(_db.adminIdentity)..where((t) => t.id.equals(1))).write(
        AdminIdentityCompanion(
          pinHash: Value(await hashPinStrong(row.pinSalt, pin)),
        ),
      );
    }
    return AdminSession._(row.name);
  }

  Future<bool> changePin(AdminSession _, String current, String next) async {
    if (!TeacherPin.isValidFormat(next)) return false;
    final row = await _row();
    if (row == null ||
        !await pinMatches(row.pinSalt, current, row.pinHash)) {
      return false;
    }
    final salt = newPinSalt();
    await (_db.update(_db.adminIdentity)..where((t) => t.id.equals(1))).write(
      AdminIdentityCompanion(
        pinSalt: Value(salt),
        pinHash: Value(await hashPinStrong(salt, next)),
        pinPlain: Value(next),
      ),
    );
    await _log('admin.pin_changed');
    return true;
  }

  // ── Teachers ──────────────────────────────────────────────────────────

  /// Adds a teacher who signs in with [pin]. Null with a reason when the
  /// name is empty or taken, or the PIN is not 4 to 8 digits.
  Future<String?> addTeacher(
    AdminSession _, {
    required String name,
    required String pin,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a name.';
    if (!TeacherPin.isValidFormat(pin)) return 'A PIN is 4 to 8 digits.';
    final taken = await (_db.select(
      _db.teacherProfiles,
    )..where((t) => t.name.lower().equals(trimmed.toLowerCase()))).get();
    if (taken.isNotEmpty) return 'That name is taken.';
    final salt = newPinSalt();
    await _db
        .into(_db.teacherProfiles)
        .insert(
          TeacherProfilesCompanion.insert(
            name: trimmed,
            pinSalt: salt,
            pinHash: await hashPinStrong(salt, pin),
            pinPlain: Value(pin),
            createdAt: DateTime.now().toUtc().toIso8601String(),
            uuid: Value(newSyncId()),
          ),
        );
    await _log('teacher.added', trimmed);
    return null;
  }

  /// Sets a teacher's PIN — for one who forgot theirs.
  Future<bool> resetTeacherPin(AdminSession _, int teacherId, String pin) async {
    if (!TeacherPin.isValidFormat(pin)) return false;
    final salt = newPinSalt();
    final n = await (_db.update(
      _db.teacherProfiles,
    )..where((t) => t.id.equals(teacherId))).write(
      TeacherProfilesCompanion(
        pinSalt: Value(salt),
        pinHash: Value(await hashPinStrong(salt, pin)),
        pinPlain: Value(pin),
      ),
    );
    if (n > 0) await _log('teacher.pin_reset', 'teacher:$teacherId');
    return n > 0;
  }

  /// Classes stop being served what their assignments no longer cover.
  Future<void> _prune() => TeachingScope(_db).pruneShares();

  /// Removes a teacher and their assignments. Their notes stay, owned by
  /// nobody, for whoever the Admin assigns next.
  Future<void> removeTeacher(AdminSession _, int teacherId) async {
    await _log('teacher.removed', 'teacher:$teacherId');
    await _db.transaction(() async {
        await (_db.delete(
          _db.teachingAssignments,
        )..where((t) => t.teacherId.equals(teacherId))).go();
        await (_db.delete(
          _db.noteOwners,
        )..where((t) => t.teacherId.equals(teacherId))).go();
        await (_db.delete(
          _db.classTeacherAssignments,
        )..where((t) => t.teacherId.equals(teacherId))).go();
        await (_db.delete(
          _db.teacherSubjects,
        )..where((t) => t.teacherId.equals(teacherId))).go();
        await (_db.delete(
          _db.teacherProfiles,
        )..where((t) => t.id.equals(teacherId))).go();
        await _prune();
      });
  }

  // ── Class Teachers ────────────────────────────────────────────────────

  /// Enrols a Class Teacher: their own sign-in (name and PIN, as any
  /// teacher's) and the classes/streams [classUuids] they may register
  /// learners into. Null when done; else why not.
  Future<String?> addClassTeacher(
    AdminSession session, {
    required String name,
    required String pin,
    required Set<String> classUuids,
  }) async {
    if (classUuids.isEmpty) return 'Pick at least one class or stream.';
    final error = await addTeacher(session, name: name, pin: pin);
    if (error != null) return error;
    final teacher =
        await (_db.select(_db.teacherProfiles)
              ..where((t) => t.name.lower().equals(name.trim().toLowerCase())))
            .getSingle();
    await setClassTeacherClasses(session, teacher.id, classUuids);
    return null;
  }

  /// Sets the classes/streams [teacherId] registers learners into, as a
  /// Class Teacher; empty removes the role. Learners already registered
  /// stay.
  Future<void> setClassTeacherClasses(
    AdminSession _,
    int teacherId,
    Set<String> classUuids,
  ) async {
    final owned = {
      for (final c in await (_db.select(
        _db.classGroups,
      )..where((t) => t.joined.equals(false))).get())
        ?c.groupUuid,
    };
    final keep = classUuids.intersection(owned);
    await _db.transaction(() async {
      await (_db.delete(_db.classTeacherAssignments)..where(
            (t) =>
                t.teacherId.equals(teacherId) &
                t.classGroupUuid.isNotIn(keep),
          ))
          .go();
      for (final uuid in keep) {
        await _db
            .into(_db.classTeacherAssignments)
            .insert(
              ClassTeacherAssignmentsCompanion.insert(
                uuid: newSyncId(),
                teacherId: teacherId,
                classGroupUuid: uuid,
                createdAt: DateTime.now().toUtc().toIso8601String(),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    await _log(
      keep.isEmpty ? 'class_teacher.removed' : 'class_teacher.classes_set',
      'teacher:$teacherId ${keep.length}',
    );
  }

  // ── Classes and streams ───────────────────────────────────────────────

  Future<int> addClass(
    AdminSession _, {
    required String className,
    String? streamName,
  }) async {
    final id = await _db.classGroupDao.createClass(
      className: className,
      streamName: streamName,
    );
    await _log('class.added', '$className ${streamName ?? ''}'.trim());
    return id;
  }

  Future<void> renameClass(
    AdminSession _,
    int id, {
    required String className,
    String? streamName,
  }) async {
    await _db.classGroupDao.renameClass(
      id,
      className: className,
      streamName: streamName,
    );
    await _log('class.renamed', '$className ${streamName ?? ''}'.trim());
  }

  /// Deletes a class, its assignments and its enrolments. Learners stay.
  Future<void> deleteClass(AdminSession _, ClassGroup group) async {
    await _log(
      'class.deleted',
      '${group.className} ${group.streamName ?? ''}'.trim(),
    );
    await _db.transaction(() async {
        final uuid = group.groupUuid;
        if (uuid != null) {
          await (_db.delete(
            _db.teachingAssignments,
          )..where((t) => t.classGroupUuid.equals(uuid))).go();
          await (_db.delete(
            _db.studentEnrolments,
          )..where((t) => t.classGroupUuid.equals(uuid))).go();
          await (_db.delete(
            _db.classTeacherAssignments,
          )..where((t) => t.classGroupUuid.equals(uuid))).go();
        }
        await _db.classGroupDao.deleteClass(group.id);
      });
  }

  // ── Subjects ──────────────────────────────────────────────────────────

  Future<CustomSubjectResult> addSubject(AdminSession _, String name) async {
    final result = await _subjects.create(name: name);
    await _log('subject.added', name.trim());
    return result;
  }

  Future<void> renameSubject(
    AdminSession _,
    String subjectId,
    String name,
  ) async {
    await _subjects.rename(subjectId, name);
    await _log('subject.renamed', '$subjectId → ${name.trim()}');
  }

  /// Deletes a subject, its materials and its assignments. A built-in
  /// subject is hidden instead, and its name is free for the school's own.
  Future<void> deleteSubject(AdminSession _, String subjectId) async {
    final id = normalizeSubjectId(subjectId);
    await (_db.delete(
      _db.teachingAssignments,
    )..where((t) => t.subjectId.equals(id))).go();
    await (_db.delete(
      _db.noteOwners,
    )..where((t) => t.subjectId.equals(id))).go();
    await (_db.delete(
      _db.teacherSubjects,
    )..where((t) => t.subjectId.equals(id))).go();
    if (CustomSubjectService.reservedIds.contains(id)) {
      await _subjects.removeBuiltIn(id);
    } else {
      await _subjects.delete(id);
    }
    await _log('subject.deleted', id);
  }

  /// Shows a removed built-in subject again. Null when done; else why not.
  Future<String?> restoreSubject(AdminSession _, String subjectId) async {
    final id = normalizeSubjectId(subjectId);
    for (final s in await _subjects.list()) {
      if (normalizeSubjectId(s.name) == id) {
        return 'The school already has a subject called "${s.name}".';
      }
    }
    await _subjects.restoreBuiltIn(id);
    await _log('subject.restored', id);
    return null;
  }

  // ── Teaching assignments ──────────────────────────────────────────────

  /// Assigns [teacherId] to teach [subjectId] to a class/stream. False
  /// when that teacher already has it.
  Future<bool> assign(
    AdminSession _, {
    required int teacherId,
    required String classGroupUuid,
    required String subjectId,
    required int academicYear,
    int term = 0,
  }) async {
    final existing =
        await (_db.select(_db.teachingAssignments)
              ..where((t) => t.teacherId.equals(teacherId))
              ..where((t) => t.classGroupUuid.equals(classGroupUuid))
              ..where((t) => t.subjectId.equals(subjectId))
              ..where((t) => t.academicYear.equals(academicYear))
              ..where((t) => t.term.equals(term)))
            .get();
    if (existing.isNotEmpty) return false;
    await _db
        .into(_db.teachingAssignments)
        .insert(
          TeachingAssignmentsCompanion.insert(
            uuid: newSyncId(),
            teacherId: teacherId,
            classGroupUuid: classGroupUuid,
            subjectId: subjectId,
            academicYear: academicYear,
            term: Value(term),
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
    await _log(
      'assignment.added',
      'teacher:$teacherId $subjectId $classGroupUuid $academicYear/$term',
    );
    return true;
  }

  Future<void> unassign(AdminSession _, int assignmentId) async {
    await (_db.delete(
      _db.teachingAssignments,
    )..where((t) => t.id.equals(assignmentId))).go();
    await _prune();
    await _log('assignment.removed', 'assignment:$assignmentId');
  }

  // ── Learners and enrolments ───────────────────────────────────────────

  Future<int?> addLearner(AdminSession _, {required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final id = await _db.studentDao.createStudent(
      StudentsCompanion.insert(name: trimmed, uuid: Value(newSyncId())),
    );
    await _log('learner.added', 'learner:$id');
    return id;
  }

  /// Enrols a learner in a class/stream for [academicYear]; their earlier
  /// active enrolment is withdrawn, never deleted.
  Future<void> enrol(
    AdminSession _, {
    required int studentId,
    required ClassGroup group,
    required int academicYear,
  }) => _db.transaction(() async {
    final uuid = group.groupUuid;
    if (uuid == null) return;
    await (_db.update(_db.studentEnrolments)
          ..where((t) => t.studentId.equals(studentId))
          ..where((t) => t.status.equals('active')))
        .write(const StudentEnrolmentsCompanion(status: Value('withdrawn')));
    await _db
        .into(_db.studentEnrolments)
        .insert(
          StudentEnrolmentsCompanion.insert(
            uuid: newSyncId(),
            studentId: studentId,
            classGroupUuid: uuid,
            academicYear: academicYear,
            createdAt: DateTime.now().toUtc().toIso8601String(),
          ),
        );
    await _db.classGroupDao.assignLearner(studentId, group.id);
    await _log('learner.enrolled', 'learner:$studentId $uuid $academicYear');
  });

  /// Withdraws a learner from their class.
  Future<void> withdraw(AdminSession _, int studentId) =>
      _db.transaction(() async {
        await (_db.update(_db.studentEnrolments)
              ..where((t) => t.studentId.equals(studentId))
              ..where((t) => t.status.equals('active')))
            .write(
              const StudentEnrolmentsCompanion(status: Value('withdrawn')),
            );
        await _db.classGroupDao.assignLearner(studentId, null);
        await _log('learner.withdrawn', 'learner:$studentId');
      });

  /// Deletes a learner and everything scoped to them.
  Future<void> deleteLearner(AdminSession _, int studentId) async {
    await _wiper.wipeStudent(studentId);
    await _log('learner.deleted', 'learner:$studentId');
  }

  /// Deletes every learner's data on this device.
  Future<void> resetAllLearners(AdminSession _) async {
    await _wiper.wipeAll();
    await _log('learners.reset');
  }

  // ── Devices ───────────────────────────────────────────────────────────

  /// Revokes a device for the whole school. It reaches other devices with
  /// the next records the Admin sends; each then refuses it and replaces
  /// the key of every class it held.
  Future<void> revokeDevice(
    AdminSession _,
    String deviceKey, {
    String name = '',
  }) async {
    await DeviceRegistry(_db).revokeSchoolWide(deviceKey, name: name);
    await _log('device.revoked', '${deviceKey.substring(0, 16)} $name'.trim());
  }
}

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(
    ref.watch(dbProvider),
    ref.watch(customSubjectServiceProvider),
    ref.watch(learnerDataWiperProvider),
  ),
);

/// The Admin's session while signed in, or null. In memory only; cleared
/// whenever the device is handed to a learner, and [kSessionLife] after
/// signing in.
final adminSessionProvider = StateProvider<AdminSession?>((ref) {
  Timer? expiry;
  ref.onDispose(() => expiry?.cancel());
  ref.listenSelf((_, next) {
    expiry?.cancel();
    if (next != null) {
      expiry = Timer(kSessionLife, () => ref.controller.state = null);
    }
  });
  return null;
});

final adminSetUpProvider = FutureProvider.autoDispose<bool>((ref) {
  if (kIsWeb) return Future.value(false);
  return ref.watch(adminServiceProvider).isSetUp();
});
