import 'dart:io';

import 'package:ai_connect_africa/collaboration/sync/progress_report.dart';
import 'package:ai_connect_africa/db/otic_database.dart';
import 'package:ai_connect_africa/features/assignments/assignments_screens.dart'
    show timingLine;
import 'package:ai_connect_africa/services/assignments/class_assignments.dart';
import 'package:ai_connect_africa/services/assignments/learner_support.dart';
import 'package:ai_connect_africa/services/learning/tutor_use.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The follow-ups to the 2026-10-12 report: "Tutor used" on assignment
/// answers, the old-build and device-clock risks, and a teacher's extra
/// help for one learner.
void main() {
  late OticDatabase db;
  late ClassAssignments service;
  late Student amina;
  late ClassGroup s2;
  final nine = DateTime.utc(2026, 10, 13, 9);

  setUp(() async {
    db = OticDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    service = ClassAssignments(db);
    final groupId = await db
        .into(db.classGroups)
        .insert(
          ClassGroupsCompanion.insert(
            className: 'S2',
            groupUuid: const Value('class-1'),
          ),
        );
    s2 = await (db.select(
      db.classGroups,
    )..where((t) => t.id.equals(groupId))).getSingle();
    final id = await db.studentDao.createStudent(
      StudentsCompanion.insert(name: 'Amina', classGroupId: Value(groupId)),
    );
    amina = (await db.studentDao.getStudentById(id))!;
  });

  tearDown(() => db.close());

  Future<ClassAssignment> make({int? minutes}) async {
    await service.create(
      subjectId: 'biology',
      title: 'Cells ${minutes ?? 'untimed'}',
      instructions: 'Name two organelles.',
      maxPoints: 10,
      minutes: minutes,
    );
    return (await service.own()).last;
  }

  Future<AssignmentSubmission> mine() async =>
      (await service.watchMine(amina.id).first).first;

  group('Tutor used on assignment answers', () {
    test(
      'untimed: a tutor reply after the learner saw it marks the answer',
      () async {
        final a = await make();
        await service.markSeen(amina.id, [a], now: nine);
        await persistTutorReply(
          db,
          amina.id,
          nine.add(const Duration(minutes: 5)),
        );
        await service.submit(
          student: amina,
          assignment: a,
          answer: 'nucleus, ribosome',
          memberKey: 'local/1',
          now: nine.add(const Duration(minutes: 20)),
        );
        expect((await mine()).tutorUsed, isTrue);
      },
    );

    test('a reply before the learner saw it does not count', () async {
      final a = await make();
      await persistTutorReply(db, amina.id, nine);
      await service.markSeen(amina.id, [
        a,
      ], now: nine.add(const Duration(hours: 1)));
      await service.submit(
        student: amina,
        assignment: a,
        answer: 'x',
        memberKey: 'local/1',
        now: nine.add(const Duration(hours: 2)),
      );
      expect((await mine()).tutorUsed, isFalse);
    });

    test('never seen on Assignments: unknown, not "no"', () async {
      final a = await make();
      await service.submit(
        student: amina,
        assignment: a,
        answer: 'x',
        memberKey: 'local/1',
      );
      expect((await mine()).tutorUsed, isNull);
    });

    test('answering again opens a new window', () async {
      final a = await make();
      await service.markSeen(amina.id, [a], now: nine);
      await persistTutorReply(
        db,
        amina.id,
        nine.add(const Duration(minutes: 1)),
      );
      await service.submit(
        student: amina,
        assignment: a,
        answer: 'first',
        memberKey: 'local/1',
        now: nine.add(const Duration(minutes: 2)),
      );
      await service.markSeen(amina.id, [
        a,
      ], now: nine.add(const Duration(minutes: 3)));
      await service.submit(
        student: amina,
        assignment: a,
        answer: 'second',
        memberKey: 'local/1',
        now: nine.add(const Duration(minutes: 4)),
      );
      final rows = await service.watchMine(amina.id).first;
      expect(
        {for (final r in rows) r.answer: r.tutorUsed},
        {'first': true, 'second': false},
      );
    });

    test('timed: a reply during the attempt marks it, even when it is handed '
        'in by itself after the app was closed', () async {
      final a = await make(minutes: 30);
      await persistTutorReply(
        db,
        amina.id,
        nine.subtract(const Duration(hours: 1)),
      );
      await service.start(amina.id, a, now: nine);
      expect(
        (await service.attempt(amina.id, a.id))!.tutorAt,
        isNull,
        reason: 'a reply before the start does not count',
      );
      await persistTutorReply(
        db,
        amina.id,
        nine.add(const Duration(minutes: 10)),
      );
      await service.submitExpired(
        student: amina,
        assignments: [a],
        memberKey: 'local/1',
        now: nine.add(const Duration(hours: 3)),
      );
      expect((await mine()).tutorUsed, isTrue);
    });

    test('timed: no reply during the attempt is "no"', () async {
      final a = await make(minutes: 30);
      await service.start(amina.id, a, now: nine);
      await service.submit(
        student: amina,
        assignment: a,
        answer: 'x',
        memberKey: 'local/1',
        now: nine.add(const Duration(minutes: 5)),
      );
      expect((await mine()).tutorUsed, isFalse);
    });

    test('the mark rides the report and the teacher stores it', () async {
      expect(
        const SubmissionPayload(
          uuid: 'u',
          assignmentId: 'a',
          subjectId: 's',
          answer: 'x',
          createdAt: 'c',
        ).toJson().containsKey('tutor_used'),
        isFalse,
        reason: 'older answers keep their report digest',
      );
      // The teacher's device: its own class and shared assignment.
      final teacherDb = OticDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(teacherDb.close);
      final teacher = ClassAssignments(teacherDb);
      await teacherDb.classSyncDao.setSchoolName('School');
      final classId = await teacherDb.classGroupDao.createClass(
        className: 'S2',
      );
      final classUuid = (await (teacherDb.select(
        teacherDb.classGroups,
      )..where((t) => t.id.equals(classId))).getSingle()).groupUuid!;
      final title = (await teacher.create(
        subjectId: 'biology',
        title: 'Cells',
        instructions: '',
        maxPoints: 5,
      ))!;
      await teacherDb.classSyncDao.setShares(
        subjectId: 'biology',
        documentTitle: title,
        classUuids: {classUuid},
      );
      final a = (await teacher.own()).single;
      final sent = SubmissionPayload(
        uuid: 'u2',
        assignmentId: a.id,
        subjectId: 'biology',
        answer: 'a',
        createdAt: 'c',
        tutorUsed: true,
      );
      await teacher.receive(
        classUuid: classUuid,
        memberKey: 'dev/1',
        learnerName: 'Amina',
        submissions: [SubmissionPayload.fromJson(sent.toJson())!],
      );
      final row =
          (await teacherDb.select(teacherDb.assignmentSubmissions).get())
              .single;
      expect(row.tutorUsed, isTrue);
    });
  });

  group('old builds and device clocks', () {
    test('the device clock rides the report but not its digest', () {
      ProgressReport report(String? sentAt) => ProgressReport(
        memberKey: 'dev/1',
        name: 'Amina',
        points: 1,
        streakDays: 0,
        lessonsCompleted: 0,
        practiceAttempted: 0,
        practiceCorrect: 0,
        scenariosCompleted: 0,
        lastActive: null,
        topics: const [],
        strengths: const [],
        weaknesses: const [],
        sentAt: sentAt,
      );
      final a = report('2026-10-13T09:00:00.000Z');
      final back = ProgressReport.fromJson(a.toJson())!;
      expect(back.sentAt, a.sentAt);
      expect(reportDigest(a), reportDigest(report('2026-10-14T10:00:00.000Z')));
      expect(reportDigest(a), reportDigest(report(null)));
      expect(
        back.clockOffset('2026-10-13T07:00:00.000Z'),
        const Duration(hours: 2),
      );
      expect(report(null).clockOffset('2026-10-13T07:00:00.000Z'), isNull);
    });

    test('a clock off by more than a few minutes is named', () {
      expect(clockNote(null), isNull);
      expect(clockNote(const Duration(minutes: 3)), isNull);
      expect(
        clockNote(const Duration(hours: 2, minutes: 5)),
        'device clock 2 h 05 min fast',
      );
      expect(
        clockNote(const Duration(minutes: -40)),
        'device clock 40 min slow',
      );
      expect(clockNote(const Duration(days: -3)), 'device clock 3 days slow');
    });

    test('the gradebook flags an older app, tutor use and the clock', () async {
      final timed = await make(minutes: 30);
      AssignmentSubmission row({String? startedAt, bool? tutorUsed}) =>
          AssignmentSubmission(
            id: 1,
            uuid: 'u',
            assignmentId: timed.id,
            subjectId: 'biology',
            memberKey: 'dev/1',
            learnerName: 'Amina',
            answer: 'x',
            createdAt: '2026-10-13T09:20:00.000Z',
            startedAt: startedAt,
            tutorUsed: tutorUsed,
            gradeVersion: 0,
          );
      expect(timingLine(timed, row()), 'older app: not timed');
      final line = timingLine(
        timed,
        row(startedAt: '2026-10-13T09:00:00.000Z', tutorUsed: true),
        clockOffset: const Duration(hours: 1),
      )!;
      expect(line, contains('Tutor used'));
      expect(line, contains('device clock 1 h 00 min fast'));
      expect(line, isNot(contains('older app')));
      final untimed = await make();
      expect(timingLine(untimed, row()), isNull);
    });
  });

  group('extra help for one learner', () {
    late LearnerSupportService support;
    const deviceKey = 'devA';
    String member() => '$deviceKey/${amina.id}';

    ProgressReport report({
      required String memberKey,
      List<
            ({
              String subject,
              String topic,
              int correct,
              int total,
              int? tutorUsed,
            })
          >
          quizzes =
          const [],
      List<({String id, String? openedAt, String? doneAt})> acks = const [],
    }) => ProgressReport(
      memberKey: memberKey,
      name: 'Amina',
      points: 0,
      streakDays: 0,
      lessonsCompleted: 0,
      practiceAttempted: 0,
      practiceCorrect: 0,
      scenariosCompleted: 0,
      lastActive: null,
      topics: const [],
      strengths: const [],
      weaknesses: const [],
      quizzes: quizzes,
      support: acks,
    );

    setUp(() => support = LearnerSupportService(db));

    test('sent to one learner only, and needs something to send', () async {
      expect(
        await support.send(
          classUuid: 'class-1',
          report: report(memberKey: member()),
          teacherId: 1,
          subjectId: 'biology',
        ),
        isNull,
      );
      await support.send(
        classUuid: 'class-1',
        report: report(memberKey: member()),
        teacherId: 1,
        subjectId: 'biology',
        message: 'Read the cells note again.',
      );
      expect(await support.outgoing('class-1', ['devB/7']), isEmpty);
      expect(await support.outgoing('class-2', [member()]), isEmpty);
      expect(
        (await support.outgoing('class-1', [member()])).single.message,
        'Read the cells note again.',
      );
    });

    test('the learner device takes it for that learner only, newer versions '
        'only, and a withdrawal hides it', () async {
      // A teacher device with its own row, mirrored to the learner device.
      final teacherDb = OticDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
      addTearDown(teacherDb.close);
      final teacher = LearnerSupportService(teacherDb);
      final id = (await teacher.send(
        classUuid: 'class-1',
        report: report(memberKey: member()),
        teacherId: 1,
        subjectId: 'biology',
        topic: 'Cells',
        quiz: true,
      ))!;
      Future<List<SupportPayload>> reply() =>
          teacher.outgoing('class-1', [member()]);

      expect(
        await support.receive(
          group: s2,
          deviceKey: 'someone-else',
          items: await reply(),
        ),
        0,
        reason: 'not addressed to a learner on this device',
      );
      expect(
        await support.receive(
          group: s2,
          deviceKey: deviceKey,
          items: await reply(),
        ),
        1,
      );
      final mine = await support.watchMine(amina.id).first;
      expect((mine.single.topic, mine.single.quiz), ('Cells', true));
      expect(
        await support.receive(
          group: s2,
          deviceKey: deviceKey,
          items: await reply(),
        ),
        0,
        reason: 'same version again changes nothing',
      );

      await support.markOpened(amina.id, id);
      await support.markDone(amina.id, id);
      final acks = await support.acks(amina.id, 'class-1');
      expect(acks.single.id, id);
      expect(acks.single.openedAt, isNotNull);
      expect(acks.single.doneAt, isNotNull);

      await teacher.withdraw(id);
      await support.receive(
        group: s2,
        deviceKey: deviceKey,
        items: await reply(),
      );
      expect(await support.watchMine(amina.id).first, isEmpty);
      expect(await support.acks(amina.id, 'class-1'), isEmpty);
    });

    test('what the learner did rides their report to the teacher', () async {
      await db
          .into(db.learnerSupport)
          .insert(
            LearnerSupportCompanion.insert(
              uuid: 'h1',
              classGroupUuid: 'class-1',
              memberKey: member(),
              studentId: Value(amina.id),
              subjectId: 'biology',
              sentAt: '2026-10-13T08:00:00.000Z',
              openedAt: const Value('2026-10-13T10:00:00.000Z'),
            ),
          );
      final reports = await buildProgressReports(
        db,
        s2,
        deviceKey: deviceKey,
      );
      final back = ProgressReport.fromJson(reports.single.toJson())!;
      expect(back.support.single.id, 'h1');
      expect(back.support.single.openedAt, '2026-10-13T10:00:00.000Z');
      expect(back.sentAt, isNotNull);
    });

    test('improvement is measured from the score when it was sent', () async {
      const before = (
        subject: 'biology',
        topic: 'Cells',
        correct: 2,
        total: 8,
        tutorUsed: 0,
      );
      final id = (await support.send(
        classUuid: 'class-1',
        report: report(memberKey: member(), quizzes: [before]),
        teacherId: 1,
        subjectId: 'biology',
        topic: 'Cells',
        quiz: true,
      ))!;
      final item = (await support.watchSent('class-1').first).single;
      expect(item.uuid, id);
      final same = LearnerSupportService.progress(
        item,
        report(memberKey: member(), quizzes: [before]),
      );
      expect((same.before?.correct, same.now), (2, null));
      final later = LearnerSupportService.progress(
        item,
        report(
          memberKey: member(),
          quizzes: [
            (
              subject: 'biology',
              topic: 'Cells',
              correct: 6,
              total: 8,
              tutorUsed: 1,
            ),
          ],
        ),
      );
      expect((later.now?.correct, later.now?.tutorUsed), (6, 1));
      expect(percent(6, 8) - percent(2, 8), 50);
    });

    test('a payload from another device is checked and clipped', () {
      expect(SupportPayload.fromJson({'uuid': 'x'}), isNull);
      final p = SupportPayload.fromJson({
        'uuid': 'x',
        'member': 'devA/1',
        'subject': 'biology',
        'topic': 'Cells',
        'message': 'm' * (kMaxSupportMessageChars + 10),
        'sent_at': '2026-10-13T08:00:00.000Z',
        'version': 1,
      })!;
      expect(p.message.length, kMaxSupportMessageChars);
      expect(p.withdrawn, isFalse);
    });
  });

  test('a v32 database upgrades to v33 and keeps its answers', () async {
    final dir = await Directory.systemTemp.createTemp('otic_migration_33');
    final file = File(p.join(dir.path, 'test.sqlite'));
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final seed = OticDatabase.forTesting(NativeDatabase(file));
    await seed.customStatement(
      "INSERT INTO assignment_submissions (uuid, assignment_id, subject_id, "
      "member_key, learner_name, answer, created_at) VALUES "
      "('u1', 'a1', 'biology', 'm', 'Amina', 'x', '2026-10-01')",
    );
    await seed.customStatement('DROP TABLE learner_support');
    await seed.customStatement(
      'ALTER TABLE assignment_submissions DROP COLUMN tutor_used',
    );
    await seed.customStatement(
      'ALTER TABLE assignment_attempts DROP COLUMN tutor_at',
    );
    await seed.customStatement('PRAGMA user_version = 32');
    await seed.close();

    for (var run = 0; run < 2; run++) {
      final upgraded = OticDatabase.forTesting(NativeDatabase(file));
      final rows = await upgraded.select(upgraded.assignmentSubmissions).get();
      expect(rows.single.answer, 'x');
      expect(rows.single.tutorUsed, isNull);
      expect(await upgraded.select(upgraded.learnerSupport).get(), isEmpty);
      expect(await upgraded.select(upgraded.assignmentAttempts).get(), isEmpty);
      await upgraded.customStatement('PRAGMA user_version = 32');
      await upgraded.close();
    }
  });
}
