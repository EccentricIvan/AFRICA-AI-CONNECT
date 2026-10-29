import 'dart:convert';
import 'dart:io';

import 'package:ai_connect_africa/collaboration/cloud/cloud_link.dart';
import 'package:ai_connect_africa/collaboration/cloud/cloud_sync.dart';
import 'package:ai_connect_africa/collaboration/cloud/http_cloud_sync.dart';
import 'package:ai_connect_africa/collaboration/sync/p2p_failover_service.dart';
import 'package:ai_connect_africa/db/otic_database.dart';
import 'package:ai_connect_africa/services/assignments/class_assignments.dart';
import 'package:ai_connect_africa/services/audit/audit_log.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// The app's cloud plug-in against the real backend (`backend/`), started
/// here on a local port. Skipped when the backend's Python environment
/// isn't installed (see backend/README.md).
void main() {
  final python = p.join(
    Directory.current.path,
    'backend',
    '.venv',
    Platform.isWindows ? 'Scripts' : 'bin',
    Platform.isWindows ? 'python.exe' : 'python',
  );
  final skip = File(python).existsSync()
      ? null
      : 'backend/.venv not installed';

  late Directory data;
  late Process server;
  late String base;
  final dbs = <OticDatabase>[];

  Map<String, String> env() => {
    ...Platform.environment,
    'OTIC_DATA_DIR': data.path,
    'OTIC_ALLOW_HTTP': '1',
  };

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    if (skip != null) return;
    data = await Directory.systemTemp.createTemp('otic_cloud_e2e');
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    server = await Process.start(
      python,
      ['-m', 'uvicorn', 'otic_cloud.main:app', '--port', '$port'],
      workingDirectory: 'backend',
      environment: env(),
    );
    server.stdout.drain<void>();
    server.stderr.drain<void>();
    base = 'http://127.0.0.1:$port';
    for (var i = 0; i < 100; i++) {
      try {
        await http.post(Uri.parse('$base/v1/enroll'), body: '{}');
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
    fail('the backend did not start');
  });

  tearDownAll(() async {
    if (skip != null) return;
    server.kill();
    await server.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);
    for (final db in dbs) {
      await db.close();
    }
    try {
      await data.delete(recursive: true);
    } catch (_) {}
  });

  OticDatabase device() {
    final db = OticDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
    dbs.add(db);
    return db;
  }

  /// Registers a school and approves it with the operator command, as the
  /// platform operator would. Returns the first Admin code.
  Future<String> provision(String name) async {
    final reg = jsonDecode(
      (await http.post(
        Uri.parse('$base/v1/schools/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'district': 'Kampala',
          'contact_name': 'Head',
          'contact_phone': '+256700000000',
        }),
      )).body,
    );
    final r = await Process.run(
      python,
      ['-m', 'otic_cloud.admin', 'approve', reg['registration_id'] as String],
      workingDirectory: 'backend',
      environment: env(),
    );
    final code = RegExp(
      r'[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}',
    ).firstMatch('${r.stdout}');
    expect(code, isNotNull, reason: '${r.stdout}${r.stderr}');
    return code![0]!;
  }

  Future<Student> learner(OticDatabase db, String name, String uuid) async {
    final id = await db.studentDao.createStudent(
      StudentsCompanion.insert(name: name, uuid: Value(uuid)),
    );
    return (await db.studentDao.getStudentById(id))!;
  }

  test('enroll, send answers once, and recover them on a new device; '
      'another school sees nothing', () async {
    // School A's Admin device.
    final adminDb = device();
    final admin = CloudLinkService(adminDb);
    await admin.enroll(
      address: base,
      code: await provision('School A'),
      role: 'admin',
    );
    expect((await admin.link())!.schoolName, 'School A');

    // A learner device, with a code from the Admin.
    final phoneDb = device();
    final phone = CloudLinkService(phoneDb);
    await phone.enroll(
      address: base,
      code: await admin.issueCode(role: 'learner'),
      role: 'learner',
    );
    final amina = await learner(phoneDb, 'Amina', 'learner-amina');
    final outbox = CloudOutboxService(phoneDb, LinkedCloudSync(phoneDb));
    final assignments = ClassAssignments(
      phoneDb,
      cloud: (kind, uuid, {recordId}) =>
          outbox.enqueue(kind, uuid, recordId: recordId),
    );
    await assignments.create(
      subjectId: 'maths',
      title: 'Fractions',
      instructions: 'Add 1/2 and 1/4.',
      maxPoints: 5,
    );
    await assignments.submit(
      student: amina,
      assignment: (await assignments.own()).single,
      answer: '3/4',
      memberKey: 'local/${amina.id}',
    );
    // The assignment is refused (a learner device doesn't publish), the
    // answer is taken; sending again doubles nothing.
    expect(await outbox.flush(), 1);
    expect(await outbox.pending(), 1);
    expect(await outbox.flush(), 0);

    // The phone is lost. A new one enrolls with a recovery code for Amina.
    final newDb = device();
    final newPhone = CloudLinkService(newDb);
    await newPhone.enroll(
      address: base,
      code: await admin.issueCode(
        role: 'learner',
        learnerUuids: ['learner-amina'],
      ),
      role: 'learner',
    );
    final again = await learner(newDb, 'Amina', 'learner-amina');
    expect(await newPhone.recoverLearner(again), 1);
    final back = await newDb.select(newDb.assignmentSubmissions).get();
    expect(back.single.answer, '3/4');
    expect(back.single.studentId, again.id);
    expect(await newPhone.recoverLearner(again), 0, reason: 'no doubles');
    // It may not recover anyone else.
    final brian = await learner(newDb, 'Brian', 'learner-brian');
    await expectLater(newPhone.recoverLearner(brian), throwsA(isA<CloudError>()));

    // School B's Admin asks for Amina: B's database has nothing of A's.
    final otherDb = device();
    final other = CloudLinkService(otherDb);
    await other.enroll(
      address: base,
      code: await provision('School B'),
      role: 'admin',
    );
    final spy = await learner(otherDb, 'Amina', 'learner-amina');
    expect(await other.recoverLearner(spy), 0);
    expect(await otherDb.select(otherDb.assignmentSubmissions).get(), isEmpty);

    // A wrong or reused code changes nothing.
    final strangerDb = device();
    await expectLater(
      CloudLinkService(strangerDb).enroll(
        address: base,
        code: 'AAAA-BBBB-CCCC',
        role: 'learner',
      ),
      throwsA(isA<CloudError>()),
    );
    expect(await CloudLinkService(strangerDb).link(), isNull);

    // Each device's audit log names what it did, and verifies.
    final log = await adminDb.select(adminDb.auditLog).get();
    expect(log.map((e) => e.action), contains('cloud.enrolled'));
    expect(log.map((e) => e.action), contains('cloud.code_issued'));
    expect(await AuditLogService(adminDb).verify(), isNull);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('a lost teacher device is replaced from its sealed cloud backup',
      () async {
    final adminDb = device();
    final admin = CloudLinkService(adminDb);
    await admin.enroll(address: base, code: await provision('School D'), role: 'admin');

    // The teacher device: a school, a class with a key, a shared note, and
    // a standby passphrase (few PBKDF2 rounds, for the test).
    final teacherDb = device();
    await teacherDb.classSyncDao.setSchoolName('School D');
    await teacherDb.classSyncDao.claimTeacherRole();
    final id = await teacherDb.classGroupDao.createClass(className: 'S2');
    final group = await (teacherDb.select(
      teacherDb.classGroups,
    )..where((t) => t.id.equals(id))).getSingle();
    await teacherDb.classSyncDao.ensureClassKey(group);
    const passphrase = 'correct horse battery';
    final failover = P2PFailoverService(teacherDb, kdfRounds: 1000);
    addTearDown(failover.dispose);
    expect((await failover.enableFailover(passphrase)).ok, isTrue);
    final teacher = CloudLinkService(teacherDb);
    await teacher.enroll(
      address: base,
      code: await admin.issueCode(role: 'teacher'),
      role: 'teacher',
      label: 'Staff room PC',
    );
    await teacher.backUpTeacherDevice();

    // The replacement, enrolled by the Admin as a teacher device.
    final newDb = device();
    final replacement = CloudLinkService(newDb);
    await replacement.enroll(
      address: base,
      code: await admin.issueCode(role: 'teacher'),
      role: 'teacher',
    );
    final backups = await replacement.teacherBackups();
    expect(backups.single.label, 'Staff room PC');
    final wrong = await replacement.restoreTeacherDevice(
      backups.single.id,
      'not the passphrase',
    );
    expect(wrong.error, isNotNull);
    expect(await replacement.link(), isNotNull, reason: 'nothing changed');

    final r = await replacement.restoreTeacherDevice(backups.single.id, passphrase);
    expect(r.error, isNull);
    expect(r.classes, 1);
    final owned = await newDb.classSyncDao.ownedClasses();
    expect(owned.single.groupUuid, group.groupUuid);
    expect(
      await replacement.link(),
      isNull,
      reason: 'it took the old device’s key, so it must link again',
    );

    // A learner device can't read teacher backups.
    final phoneDb = device();
    final phone = CloudLinkService(phoneDb);
    await phone.enroll(
      address: base,
      code: await admin.issueCode(role: 'learner'),
      role: 'learner',
    );
    await expectLater(phone.teacherBackups(), throwsA(isA<CloudError>()));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('a revoked device is refused', () async {
    final adminDb = device();
    final admin = CloudLinkService(adminDb);
    await admin.enroll(address: base, code: await provision('School C'), role: 'admin');
    final tabletDb = device();
    final tablet = CloudLinkService(tabletDb);
    await tablet.enroll(
      address: base,
      code: await admin.issueCode(role: 'teacher'),
      role: 'teacher',
    );
    final key = (await admin.devices()).firstWhere((d) => d.role == 'teacher').key;
    await admin.revoke(key);
    await expectLater(tablet.devices(), throwsA(isA<CloudError>()));
    final s = await learner(tabletDb, 'Amina', 'x');
    await expectLater(tablet.recoverLearner(s), throwsA(isA<CloudError>()));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
