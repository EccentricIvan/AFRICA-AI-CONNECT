import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/progress_report.dart';
import '../../collaboration/sync/sync_ids.dart';
import '../../db/daos/topic_resource_dao.dart' show kAssignmentRecordTopicKey;
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../notes/note_quiz_store.dart';

/// Longest message a teacher may send with extra help.
const kMaxSupportMessageChars = 1000;

/// Most items one learner's device takes per sync.
const kMaxSupportPerLearner = 50;

/// Extra help as it travels from the teacher's device to the learner's, in
/// the (sealed, teacher-signed) reply to that learner's progress report.
class SupportPayload {
  const SupportPayload({
    required this.uuid,
    required this.memberKey,
    required this.subjectId,
    required this.topic,
    required this.message,
    required this.quiz,
    required this.sentAt,
    required this.version,
    this.documentTitle,
    this.withdrawn = false,
  });

  SupportPayload.fromRow(LearnerSupportItem r)
    : this(
        uuid: r.uuid,
        memberKey: r.memberKey,
        subjectId: r.subjectId,
        topic: r.topic,
        message: r.message,
        quiz: r.quiz,
        sentAt: r.sentAt,
        version: r.version,
        documentTitle: r.documentTitle,
        withdrawn: r.withdrawn,
      );

  final String uuid;
  final String memberKey;
  final String subjectId;
  final String topic;
  final String? documentTitle;
  final String message;
  final bool quiz;
  final String sentAt;
  final int version;
  final bool withdrawn;

  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'member': memberKey,
    'subject': subjectId,
    'topic': topic,
    'document': ?documentTitle,
    'message': message,
    'quiz': quiz,
    'sent_at': sentAt,
    'version': version,
    if (withdrawn) 'withdrawn': true,
  };

  /// Null when [json] isn't one. Clipped, like every field another device
  /// sends.
  static SupportPayload? fromJson(Object? json) {
    if (json is! Map) return null;
    final uuid = json['uuid'],
        member = json['member'],
        subject = json['subject'];
    final topic = json['topic'], message = json['message'];
    final sentAt = json['sent_at'], version = json['version'];
    final doc = json['document'];
    if (uuid is! String ||
        uuid.isEmpty ||
        uuid.length > 64 ||
        member is! String ||
        member.length > 120 ||
        subject is! String ||
        subject.length > 60 ||
        topic is! String ||
        topic.length > 200 ||
        message is! String ||
        sentAt is! String ||
        sentAt.length > 40 ||
        version is! int ||
        version <= 0 ||
        (doc != null && (doc is! String || doc.length > 300))) {
      return null;
    }
    return SupportPayload(
      uuid: uuid,
      memberKey: member,
      subjectId: subject,
      topic: topic,
      documentTitle: doc as String?,
      message: message.length > kMaxSupportMessageChars
          ? message.substring(0, kMaxSupportMessageChars)
          : message,
      quiz: json['quiz'] == true,
      sentAt: sentAt,
      version: version,
      withdrawn: json['withdrawn'] == true,
    );
  }
}

/// A learner's quiz score on a support item's topic: when it was sent, and
/// in their latest report.
typedef SupportProgress = ({
  ({int correct, int total})? before,
  ({int correct, int total, int? tutorUsed})? now,
});

/// Percent right, rounded.
int percent(int correct, int total) =>
    total == 0 ? 0 : (100 * correct / total).round();

/// Extra help from a teacher to one learner: a message, a note to read and
/// a quiz on one topic. The teacher sees whether the learner opened it and
/// how their quiz score on the topic changed since.
///
/// It reaches only that learner's device: it rides the teacher's reply to
/// the device's own progress report, never the class's note channels,
/// which every classmate's device receives.
class LearnerSupportService {
  LearnerSupportService(this._db);

  final OticDatabase _db;

  // ── Teacher ───────────────────────────────────────────────────────────

  /// Sends extra help to the learner [memberKey] of [classUuid]; it reaches
  /// their device at its next Sync. Their latest quiz round on [topic], from
  /// [report], is kept to measure against. Returns the item's id, or null
  /// when there is nothing to send. The caller checks the teacher may
  /// (`Policy` → `SupportLearner`).
  Future<String?> send({
    required String classUuid,
    required ProgressReport report,
    required int? teacherId,
    required String subjectId,
    String topic = '',
    String? documentTitle,
    String message = '',
    bool quiz = false,
    DateTime? now,
  }) async {
    final text = message.trim();
    final t = topic.trim();
    final doc = documentTitle?.trim();
    if (text.isEmpty &&
        (doc == null || doc.isEmpty) &&
        !(quiz && t.isNotEmpty)) {
      return null;
    }
    final before = _latestQuiz(report, subjectId, t);
    final uuid = newSyncId();
    await _db
        .into(_db.learnerSupport)
        .insert(
          LearnerSupportCompanion.insert(
            uuid: uuid,
            classGroupUuid: classUuid,
            memberKey: report.memberKey,
            learnerName: Value(report.name),
            teacherId: Value(teacherId),
            subjectId: subjectId,
            topic: Value(t),
            documentTitle: Value(doc == null || doc.isEmpty ? null : doc),
            message: Value(
              text.length > kMaxSupportMessageChars
                  ? text.substring(0, kMaxSupportMessageChars)
                  : text,
            ),
            quiz: Value(quiz && t.isNotEmpty),
            baselineCorrect: Value(before?.correct),
            baselineTotal: Value(before?.total),
            sentAt: (now ?? DateTime.now()).toUtc().toIso8601String(),
          ),
        );
    return uuid;
  }

  /// What extra help in [subjectId] can point [classUuid]'s learners to:
  /// this device's notes shared with that class (never an assignment's),
  /// and the quiz topics written from them — what their devices hold.
  Future<({List<String> notes, List<String> topics})> offerable(
    String classUuid,
    String subjectId,
  ) async {
    final shared = {
      for (final r
          in await (_db.select(_db.resourceShares)
                ..where((t) => t.classGroupUuid.equals(classUuid))
                ..where((t) => t.subjectId.equals(subjectId)))
              .get())
        r.documentTitle,
    };
    final assignments = {
      for (final r
          in await (_db.select(_db.topicResources)
                ..where((t) => t.subjectId.equals(subjectId))
                ..where((t) => t.topicKey.equals(kAssignmentRecordTopicKey))
                ..where((t) => t.classGroupUuid.isNull()))
              .get())
        r.documentTitle ?? r.resourceTitle,
    };
    final notes = shared.difference(assignments);
    final topics = <String>{
      for (final q in await NoteQuizStore(_db).questions(subjectId))
        if (notes.contains(q.documentTitle)) q.topic,
    };
    return (notes: notes.toList()..sort(), topics: topics.toList()..sort());
  }

  /// Takes an item back: its version goes up, so the learner's device
  /// hides it at its next Sync.
  Future<void> withdraw(String uuid) async {
    final row = await _byUuid(uuid);
    if (row == null || row.studentId != null || row.withdrawn) return;
    await (_db.update(
      _db.learnerSupport,
    )..where((t) => t.id.equals(row.id))).write(
      LearnerSupportCompanion(
        withdrawn: const Value(true),
        version: Value(row.version + 1),
      ),
    );
  }

  /// What this device sent to [classUuid]'s learners, newest first.
  Stream<List<LearnerSupportItem>> watchSent(String classUuid) =>
      (_db.select(_db.learnerSupport)
            ..where((t) => t.classGroupUuid.equals(classUuid))
            ..where((t) => t.studentId.isNull())
            ..where((t) => t.withdrawn.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.sentAt)]))
          .watch();

  /// On the teacher's device, answering a progress report: the items for
  /// exactly the learners [memberKeys] that device reported, withdrawn ones
  /// included so it can hide them.
  Future<List<SupportPayload>> outgoing(
    String classUuid,
    Iterable<String> memberKeys,
  ) async {
    final keys = memberKeys.toSet();
    if (keys.isEmpty) return const [];
    final rows =
        await (_db.select(_db.learnerSupport)
              ..where((t) => t.classGroupUuid.equals(classUuid))
              ..where((t) => t.studentId.isNull())
              ..where((t) => t.memberKey.isIn(keys))
              ..orderBy([(t) => OrderingTerm.desc(t.sentAt)]))
            .get();
    final perMember = <String, int>{};
    return [
      for (final r in rows)
        if ((perMember[r.memberKey] = (perMember[r.memberKey] ?? 0) + 1) <=
            kMaxSupportPerLearner)
          SupportPayload.fromRow(r),
    ];
  }

  /// How [item]'s learner did on its topic's quiz, before and in [report]
  /// (their latest). Null `now` until they take it after it was sent —
  /// or when their report still shows the round from before.
  static SupportProgress progress(
    LearnerSupportItem item,
    ProgressReport? report,
  ) {
    final before = item.baselineTotal == null || item.baselineTotal == 0
        ? null
        : (correct: item.baselineCorrect ?? 0, total: item.baselineTotal!);
    if (report == null || item.topic.isEmpty) {
      return (before: before, now: null);
    }
    final q = _latestQuiz(report, item.subjectId, item.topic);
    if (q == null) return (before: before, now: null);
    // The same round as at sending: nothing new yet.
    final ack = report.support.where((s) => s.id == item.uuid).firstOrNull;
    if (before != null &&
        q.correct == before.correct &&
        q.total == before.total &&
        ack?.doneAt == null) {
      return (before: before, now: null);
    }
    return (before: before, now: q);
  }

  static ({int correct, int total, int? tutorUsed})? _latestQuiz(
    ProgressReport report,
    String subjectId,
    String topic,
  ) {
    if (topic.isEmpty) return null;
    final q = report.quizzes
        .where((q) => q.subject == subjectId && q.topic == topic)
        .firstOrNull;
    return q == null
        ? null
        : (correct: q.correct, total: q.total, tutorUsed: q.tutorUsed);
  }

  // ── Learner ───────────────────────────────────────────────────────────

  /// On the learner's device, from its teacher's reply: takes items for
  /// learners of [group] on this device ([deviceKey]), newer versions only.
  /// Keeps what the learner did with them. Returns how many changed.
  Future<int> receive({
    required ClassGroup group,
    required String deviceKey,
    required List<SupportPayload> items,
  }) async {
    final uuid = group.groupUuid;
    if (uuid == null || items.isEmpty) return 0;
    final learners = {
      for (final s in await (_db.select(
        _db.students,
      )..where((t) => t.classGroupId.equals(group.id))).get())
        '$deviceKey/${s.id}': s.id,
    };
    var changed = 0;
    await _db.transaction(() async {
      for (final i in items) {
        final studentId = learners[i.memberKey];
        if (studentId == null) continue;
        final existing = await _byUuid(i.uuid);
        if (existing != null &&
            (existing.studentId != studentId ||
                existing.version >= i.version)) {
          continue;
        }
        final row = LearnerSupportCompanion(
          uuid: Value(i.uuid),
          classGroupUuid: Value(uuid),
          memberKey: Value(i.memberKey),
          studentId: Value(studentId),
          subjectId: Value(i.subjectId),
          topic: Value(i.topic),
          documentTitle: Value(i.documentTitle),
          message: Value(i.message),
          quiz: Value(i.quiz),
          sentAt: Value(i.sentAt),
          version: Value(i.version),
          withdrawn: Value(i.withdrawn),
        );
        if (existing == null) {
          await _db.into(_db.learnerSupport).insert(row);
        } else {
          await (_db.update(
            _db.learnerSupport,
          )..where((t) => t.id.equals(existing.id))).write(row);
        }
        changed++;
      }
    });
    return changed;
  }

  /// [studentId]'s extra help, newest first.
  Stream<List<LearnerSupportItem>> watchMine(int studentId) =>
      (_db.select(_db.learnerSupport)
            ..where((t) => t.studentId.equals(studentId))
            ..where((t) => t.withdrawn.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.sentAt)]))
          .watch();

  Future<void> markOpened(int studentId, String uuid) =>
      _stamp(studentId, uuid, done: false);

  Future<void> markDone(int studentId, String uuid) =>
      _stamp(studentId, uuid, done: true);

  Future<void> _stamp(int studentId, String uuid, {required bool done}) async {
    final row = await _byUuid(uuid);
    if (row == null || row.studentId != studentId) return;
    final at = DateTime.now().toUtc().toIso8601String();
    await (_db.update(
      _db.learnerSupport,
    )..where((t) => t.id.equals(row.id))).write(
      LearnerSupportCompanion(
        openedAt: Value(row.openedAt ?? at),
        doneAt: done ? Value(row.doneAt ?? at) : const Value.absent(),
      ),
    );
  }

  /// What [studentId] did with the help received for [classUuid] — what
  /// their progress report carries back.
  Future<List<({String id, String? openedAt, String? doneAt})>> acks(
    int studentId,
    String classUuid,
  ) async => [
    for (final r
        in await (_db.select(_db.learnerSupport)
              ..where((t) => t.studentId.equals(studentId))
              ..where((t) => t.classGroupUuid.equals(classUuid))
              ..where((t) => t.withdrawn.equals(false))
              ..orderBy([(t) => OrderingTerm.desc(t.sentAt)])
              ..limit(ProgressReport.maxSupport))
            .get())
      (id: r.uuid, openedAt: r.openedAt, doneAt: r.doneAt),
  ];

  Future<LearnerSupportItem?> _byUuid(String uuid) => (_db.select(
    _db.learnerSupport,
  )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
}

final learnerSupportProvider = Provider<LearnerSupportService>(
  (ref) => LearnerSupportService(ref.watch(dbProvider)),
);
