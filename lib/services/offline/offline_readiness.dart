import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../ai_core/model/model_locations.dart'
    show resolveAppStorageDirectory;
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../assignments/class_assignments.dart';
import '../assignments/learner_support.dart';
import '../notes/note_pdf_store.dart';

/// What a learner has on this device for working without the teacher's
/// device or a network: their class's subjects and note PDFs, their
/// assignments and their state, extra help, and how much space it takes.
class OfflineReadiness {
  const OfflineReadiness({
    required this.lastSync,
    required this.subjects,
    required this.pdfsHeld,
    required this.pdfsMissing,
    required this.missingBytes,
    required this.partialBytes,
    required this.toDo,
    required this.awaitingSync,
    required this.graded,
    required this.help,
    required this.pdfBytes,
    required this.databaseBytes,
  });

  /// When the class last synced with its teacher (this device's clock);
  /// null when it never has.
  final DateTime? lastSync;
  final int subjects;
  final int pdfsHeld;

  /// Note PDFs the class has that are not on this device yet.
  final int pdfsMissing;
  final int missingBytes;

  /// Of [missingBytes], how much is already downloaded (it carries on at
  /// the next sync).
  final int partialBytes;

  /// The learner's assignments not handed in yet (and still open).
  final int toDo;

  /// Handed in, but not yet on the teacher's device.
  final int awaitingSync;
  final int graded;

  /// Extra help from the teacher not marked done.
  final int help;
  final int pdfBytes;
  final int databaseBytes;

  /// Ready when nothing the class has is missing here.
  bool get ready => lastSync != null && pdfsMissing == 0;

  static Future<OfflineReadiness> of(
    OticDatabase db,
    NotePdfStore pdfs, {
    required ClassGroup group,
    Student? learner,
    Future<int> Function()? databaseBytes,
    DateTime? now,
  }) async {
    final uuid = group.groupUuid;
    final at = now ?? DateTime.now();
    final states = uuid == null
        ? const <SyncStateData>[]
        : await (db.select(
            db.syncState,
          )..where((t) => t.classGroupUuid.equals(uuid))).get();
    DateTime? last;
    for (final s in states) {
      final t = DateTime.tryParse(s.lastSyncedAt);
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    var held = 0, missing = 0, missingBytes = 0, partial = 0;
    if (uuid != null) {
      for (final pdf in await pdfs.recorded(classUuid: uuid)) {
        if (await pdfs.has(pdf.sha256)) {
          held++;
        } else {
          missing++;
          missingBytes += pdf.bytes;
          partial += await pdfs.partialLength(pdf.sha256);
        }
      }
    }

    var toDo = 0, awaiting = 0, graded = 0, help = 0;
    if (learner != null) {
      final assignments = ClassAssignments(db);
      final mine = await assignments.watchMine(learner.id).first;
      final answered = {for (final s in mine) s.assignmentId};
      for (final a in await assignments.visible(uuid)) {
        if (!answered.contains(a.id) && !a.closed(at)) toDo++;
      }
      for (final s in mine) {
        if (s.grade != null) {
          graded++;
        } else if (s.receivedAt == null) {
          awaiting++;
        }
      }
      help = [
        for (final i in await LearnerSupportService(
          db,
        ).watchMine(learner.id).first)
          if (i.doneAt == null) i,
      ].length;
    }

    return OfflineReadiness(
      lastSync: last,
      subjects: {
        for (final s in states)
          if (s.channelDigest != null) s.subjectId,
      }.length,
      pdfsHeld: held,
      pdfsMissing: missing,
      missingBytes: missingBytes,
      partialBytes: partial,
      toDo: toDo,
      awaitingSync: awaiting,
      graded: graded,
      help: help,
      pdfBytes: await pdfs.storedBytes(),
      databaseBytes: await (databaseBytes ?? _databaseBytes)(),
    );
  }

  /// The database file and its write-ahead log.
  static Future<int> _databaseBytes() async {
    final dir = await resolveAppStorageDirectory();
    var total = 0;
    for (final name in [
      'otic_student_db.sqlite',
      'otic_student_db.sqlite-wal',
    ]) {
      final f = File(p.join(dir.path, name));
      if (await f.exists()) total += await f.length();
    }
    return total;
  }
}

/// "12.4 MB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// The active learner's readiness for [ClassGroup.id]; refreshed by
/// invalidating it after a sync.
final offlineReadinessProvider = FutureProvider.autoDispose
    .family<OfflineReadiness?, int>((ref, classId) async {
      final db = ref.watch(dbProvider);
      final group = await (db.select(
        db.classGroups,
      )..where((t) => t.id.equals(classId))).getSingleOrNull();
      if (group == null) return null;
      return OfflineReadiness.of(
        db,
        ref.watch(notePdfStoreProvider),
        group: group,
        learner: await ref.watch(activeStudentProvider.future),
      );
    });
