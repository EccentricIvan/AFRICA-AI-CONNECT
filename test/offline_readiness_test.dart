import 'dart:io';

import 'package:ai_connect_africa/db/otic_database.dart';
import 'package:ai_connect_africa/services/assignments/class_assignments.dart';
import 'package:ai_connect_africa/services/notes/note_pdf_store.dart';
import 'package:ai_connect_africa/services/offline/offline_readiness.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late OticDatabase db;
  late NotePdfStore pdfs;
  late Directory dir;
  late ClassGroup group;
  late Student amina;

  setUp(() async {
    db = OticDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    dir = await Directory.systemTemp.createTemp('offline_ready');
    pdfs = NotePdfStore(db, root: () async => dir);
    final id = await db
        .into(db.classGroups)
        .insert(
          ClassGroupsCompanion.insert(
            className: 'S2',
            groupUuid: const Value('class-1'),
            joined: const Value(true),
          ),
        );
    group = await (db.select(
      db.classGroups,
    )..where((t) => t.id.equals(id))).getSingle();
    final s = await db.studentDao.createStudent(
      StudentsCompanion.insert(name: 'Amina', classGroupId: Value(id)),
    );
    amina = (await db.studentDao.getStudentById(s))!;
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> receivedPdf(String title, String sha, int bytes) => db
      .into(db.topicResources)
      .insert(
        TopicResourcesCompanion.insert(
          subjectId: 'biology',
          topicKey: kPdfMarkerTopic,
          resourceTitle: title,
          contentChunk: NotePdf.markerText(sha, 3, bytes),
          createdAt: '2026-10-13T08:00:00Z',
          documentTitle: Value(title),
          classGroupUuid: const Value('class-1'),
        ),
      );

  Future<OfflineReadiness> readiness() => OfflineReadiness.of(
    db,
    pdfs,
    group: group,
    learner: amina,
    databaseBytes: () async => 4096,
  );

  test('never synced is not ready', () async {
    final r = await readiness();
    expect(r.ready, isFalse);
    expect(r.lastSync, isNull);
    expect(r.databaseBytes, 4096);
  });

  test('counts held and missing PDFs, with what is already downloaded',
      () async {
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            classGroupUuid: 'class-1',
            subjectId: 'biology',
            lastSyncedAt: '2026-10-13T09:00:00Z',
            channelDigest: const Value('d'),
          ),
        );
    final held = Uint8List.fromList(List.filled(100, 7));
    final heldSha = (await pdfs.put(held))!;
    await receivedPdf('Cells', heldSha, held.length);
    final missingSha = 'a' * 64;
    await receivedPdf('Tissues', missingSha, 5000);
    await pdfs.appendPartial(missingSha, List.filled(1200, 1), 0);

    final r = await readiness();
    expect(r.subjects, 1);
    expect((r.pdfsHeld, r.pdfsMissing), (1, 1));
    expect((r.missingBytes, r.partialBytes), (5000, 1200));
    expect(r.pdfBytes, 100 + 1200);
    expect(r.ready, isFalse);
    expect(r.lastSync, DateTime.utc(2026, 10, 13, 9));

    await pdfs.dropPartial(missingSha);
    await (db.delete(
      db.topicResources,
    )..where((t) => t.resourceTitle.equals('Tissues'))).go();
    expect((await readiness()).ready, isTrue);
  });

  test('assignments to do, waiting for Sync and graded', () async {
    final service = ClassAssignments(db);
    for (final t in ['One', 'Two', 'Three']) {
      await service.create(
        subjectId: 'biology',
        title: t,
        instructions: '',
        maxPoints: 5,
      );
    }
    final all = await service.own();
    await service.submit(
      student: amina,
      assignment: all[0],
      answer: 'a',
      memberKey: 'local/1',
    );
    await service.submit(
      student: amina,
      assignment: all[1],
      answer: 'b',
      memberKey: 'local/1',
    );
    final graded = (await service.watchMine(amina.id).first).firstWhere(
      (s) => s.assignmentId == all[1].id,
    );
    await service.applyGrades([
      GradePayload(uuid: graded.uuid, grade: 4, version: 1),
    ]);
    final r = await readiness();
    expect((r.toDo, r.awaitingSync, r.graded), (1, 1, 1));
  });
}
