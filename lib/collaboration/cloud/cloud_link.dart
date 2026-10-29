import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../services/audit/audit_log.dart';
import '../sync/device_keys.dart' show boxPublicKey;
import '../sync/device_registry.dart';
import '../sync/p2p_failover_service.dart'
    show P2PFailoverService, PromotionResult, buildSealedLedger;
import 'cloud_sync.dart';
import 'http_cloud_sync.dart';

/// Roles a device may enroll in its school's cloud as.
const kCloudRoles = ['learner', 'teacher', 'admin'];

/// A device of the school, as the cloud lists it for the Admin.
typedef CloudDevice = ({
  String key,
  String role,
  String label,
  String status,
});

/// This device's link to its school's cloud (`cloud_link`), and what it can
/// do there. Off until enrolled with a one-time code; never needed by any
/// feature.
class CloudLinkService {
  CloudLinkService(this._db, {this.httpClient});

  final OticDatabase _db;

  /// Tests pass their own client; null uses a fresh one per call.
  final http.Client Function()? httpClient;

  Future<CloudLinkData?> link() => (_db.select(
    _db.cloudLink,
  )..where((t) => t.id.equals(1))).getSingleOrNull();

  Stream<CloudLinkData?> watch() => (_db.select(
    _db.cloudLink,
  )..where((t) => t.id.equals(1))).watchSingleOrNull();

  Future<CloudClient> _clientFor(String baseUrl) async => CloudClient(
    baseUrl: baseUrl,
    signingSeed: (await _db.classSyncDao.identity()).signingSeed,
    client: httpClient?.call(),
  );

  /// Enrolls this device with a one-time [code] from the school's Admin
  /// (or, for the first Admin, the platform operator). Throws [CloudError]
  /// when refused; nothing is saved then.
  Future<CloudLinkData> enroll({
    required String address,
    required String code,
    required String role,
    String label = '',
  }) async {
    final url = CloudClient.normalizeUrl(address);
    if (url == null) throw const CloudError('That address doesn’t look right');
    if (!kCloudRoles.contains(role)) throw const CloudError('Unknown role');
    final client = await _clientFor(url);
    try {
      final reply = await client.enroll(
        code: code,
        role: role,
        boxKey: await boxPublicKey(await DeviceRegistry(_db).boxSeed()),
        label: label,
      );
      final school = reply['school'];
      final name = school is Map && school['name'] is String
          ? school['name'] as String
          : 'School';
      await _db
          .into(_db.cloudLink)
          .insertOnConflictUpdate(
            CloudLinkCompanion.insert(
              id: const Value(1),
              baseUrl: url,
              schoolName: name,
              role: role,
              enrolledAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
      await AuditLogService(
        _db,
      ).record('device', 'cloud.enrolled', detail: '$role $url');
      return (await link())!;
    } finally {
      client.close();
    }
  }

  /// Stops using the cloud on this device. Records stay queued; nothing on
  /// the server is deleted.
  Future<void> unlink() async {
    await (_db.delete(_db.cloudLink)..where((t) => t.id.equals(1))).go();
    await AuditLogService(_db).record('device', 'cloud.unlinked');
  }

  Future<T> _with<T>(Future<T> Function(CloudClient c) run) async {
    final l = await link();
    if (l == null) throw const CloudError('Not linked to a school cloud');
    final client = await _clientFor(l.baseUrl);
    try {
      return await run(client);
    } finally {
      client.close();
    }
  }

  /// Notes the outcome of a send on the link, for the screen.
  Future<void> noteSent(String? error) =>
      (_db.update(_db.cloudLink)..where((t) => t.id.equals(1))).write(
        CloudLinkCompanion(
          lastSentAt: Value(DateTime.now().toUtc().toIso8601String()),
          lastError: Value(error),
        ),
      );

  // ── Admin ─────────────────────────────────────────────────────────────

  /// A one-time code for another device of the school. With
  /// [learnerUuids], a recovery code: the device it enrolls may download
  /// those learners' work.
  Future<String> issueCode({
    required String role,
    int hours = 72,
    List<String> learnerUuids = const [],
  }) async {
    final reply = await _with(
      (c) => c.signed(
        'POST',
        '/v1/enrollment-codes',
        json: {
          'role': role,
          'expires_hours': hours,
          if (learnerUuids.isNotEmpty) 'learner_uuids': learnerUuids,
        },
      ),
    );
    final code = reply['code'];
    if (code is! String) throw const CloudError('No code came back');
    await AuditLogService(_db).record(
      'admin',
      'cloud.code_issued',
      detail: '$role${learnerUuids.isEmpty ? '' : ' recovery'}',
    );
    return code;
  }

  Future<List<CloudDevice>> devices() async {
    final reply = await _with((c) => c.signed('GET', '/v1/devices'));
    return [
      if (reply['devices'] case final List rows)
        for (final d in rows)
          if (d is Map && d['device_key'] is String)
            (
              key: d['device_key'] as String,
              role: '${d['role']}',
              label: '${d['label'] ?? ''}',
              status: '${d['status']}',
            ),
    ];
  }

  Future<void> revoke(String deviceKey) async {
    await _with(
      (c) => c.signed(
        'POST',
        '/v1/devices/revoke',
        json: {'device_key': deviceKey},
      ),
    );
    await AuditLogService(
      _db,
    ).record('admin', 'cloud.device_revoked', detail: deviceKey.substring(0, 16));
  }

  // ── Teacher device recovery ───────────────────────────────────────────

  /// Uploads this teacher device's host backup — its classes, keys and
  /// shared notes, sealed on the device under the standby passphrase
  /// (Teacher → Sync → Standby), so the server can't open it. Throws
  /// [CloudError] when there is nothing to back up yet.
  Future<void> backUpTeacherDevice() async {
    final ledger = await buildSealedLedger(_db);
    if (ledger == null) {
      throw const CloudError(
        'Set a standby passphrase first (Teacher → Sync)',
      );
    }
    await _with(
      (c) => c.signed('PUT', '/v1/backups/host', json: {'ledger': ledger}),
    );
    await AuditLogService(_db).record('teacher', 'cloud.backed_up');
  }

  /// The school's teacher-device backups, newest first.
  Future<List<({int id, String label, String at})>> teacherBackups() async {
    final reply = await _with((c) => c.signed('GET', '/v1/backups/host'));
    return [
      if (reply['backups'] case final List rows)
        for (final r in rows)
          if (r is Map && r['id'] is int)
            (id: r['id'] as int, label: '${r['label'] ?? ''}', at: '${r['at']}'),
    ];
  }

  /// Takes over as the teacher device of a lost or replaced one, from its
  /// backup [id], if [passphrase] opens it — the same takeover as a
  /// standby's (`P2PFailoverService.promoteToHostNode`).
  Future<PromotionResult> restoreTeacherDevice(
    int id,
    String passphrase, {
    int? ownerTeacherId,
  }) async {
    final reply = await _with((c) => c.signed('GET', '/v1/backups/host/$id'));
    final ledger = reply['ledger'];
    if (ledger is! Map) throw const CloudError('Not a valid backup');
    final failover = P2PFailoverService(_db);
    final keyBefore = (await _db.classSyncDao.identity()).signingSeed;
    try {
      final result = await failover.promoteToHostNode(
        passphrase,
        Map<String, dynamic>.from(ledger),
        ownerTeacherId: ownerTeacherId,
      );
      await AuditLogService(_db).record(
        'teacher',
        result.error == null ? 'cloud.restored' : 'refused.restore',
      );
      // Taking over may give this device the old one's key; the cloud
      // knows the device by its key, so it must be linked again.
      if ((await _db.classSyncDao.identity()).signingSeed != keyBefore) {
        await (_db.delete(_db.cloudLink)..where((t) => t.id.equals(1))).go();
      }
      return result;
    } finally {
      failover.dispose();
    }
  }

  // ── Recovery ──────────────────────────────────────────────────────────

  /// Brings [student]'s answers and grades back from the cloud onto this
  /// device — after a lost or replaced device. Matched by the learner's
  /// portable uuid (from the Admin's records). Answers already here are
  /// kept; a grade is taken only when newer. Returns how many answers were
  /// added.
  Future<int> recoverLearner(Student student) async {
    final uuid = student.uuid;
    if (uuid == null) throw const CloudError('This learner has no school id');
    final reply = await _with(
      (c) => c.signed(
        'GET',
        '/v1/records?kind=submission&learner_uuid=${Uri.encodeQueryComponent(uuid)}',
      ),
    );
    var added = 0;
    await _db.transaction(() async {
      for (final r in [
        if (reply['records'] case final List rows) ...rows,
      ]) {
        if (r is! Map) continue;
        final s = r['submission'];
        if (s is! Map) continue;
        final sub = s['uuid'], assignment = s['assignment'];
        final subject = s['subject'], answer = s['answer'];
        final created = s['created_at'];
        if (sub is! String ||
            assignment is! String ||
            subject is! String ||
            answer is! String ||
            created is! String) {
          continue;
        }
        final existing = await (_db.select(
          _db.assignmentSubmissions,
        )..where((t) => t.uuid.equals(sub))).getSingleOrNull();
        final g = r['grade'];
        final grade = g is Map && g['grade'] is int && g['version'] is int
            ? g
            : null;
        if (existing == null) {
          await _db
              .into(_db.assignmentSubmissions)
              .insert(
                AssignmentSubmissionsCompanion.insert(
                  uuid: sub,
                  assignmentId: assignment,
                  subjectId: subject,
                  studentId: Value(student.id),
                  memberKey: 'local/${student.id}',
                  learnerName: student.name,
                  answer: answer,
                  createdAt: created,
                  startedAt: Value(
                    s['started_at'] is String ? s['started_at'] as String : null,
                  ),
                  tutorUsed: Value(
                    s['tutor_used'] is bool ? s['tutor_used'] as bool : null,
                  ),
                  // It reached the school before: it isn't waiting for Sync.
                  receivedAt: Value(DateTime.now().toUtc().toIso8601String()),
                  grade: Value(grade?['grade'] as int?),
                  feedback: Value(
                    grade?['feedback'] is String ? grade!['feedback'] as String : null,
                  ),
                  gradeVersion: Value((grade?['version'] as int?) ?? 0),
                  gradedAt: Value(
                    grade?['graded_at'] is String ? grade!['graded_at'] as String : null,
                  ),
                ),
              );
          added++;
        } else if (grade != null &&
            existing.studentId == student.id &&
            (grade['version'] as int) > existing.gradeVersion) {
          await (_db.update(
            _db.assignmentSubmissions,
          )..where((t) => t.id.equals(existing.id))).write(
            AssignmentSubmissionsCompanion(
              grade: Value(grade['grade'] as int),
              gradeVersion: Value(grade['version'] as int),
              feedback: Value(
                grade['feedback'] is String ? grade['feedback'] as String : null,
              ),
            ),
          );
        }
      }
    });
    await AuditLogService(
      _db,
    ).record('device', 'cloud.recovered', detail: 'learner:${student.id} $added');
    return added;
  }
}

final cloudLinkServiceProvider = Provider<CloudLinkService>(
  (ref) => CloudLinkService(ref.watch(dbProvider)),
);

final cloudLinkProvider = StreamProvider<CloudLinkData?>(
  (ref) => ref.watch(cloudLinkServiceProvider).watch(),
);

/// The school cloud for this device, read from `cloud_link` when a send
/// starts: off (nothing sent, records stay queued) until it enrolls.
class LinkedCloudSync extends CloudSyncAdapter {
  LinkedCloudSync(this._db, {this.httpClient});

  final OticDatabase _db;
  final http.Client Function()? httpClient;

  @override
  bool get enabled => true;

  @override
  Future<bool> ready() async =>
      await CloudLinkService(_db, httpClient: httpClient).link() != null;

  @override
  Future<Set<String>> push(List<CloudRecord> records) async {
    final link = await CloudLinkService(_db, httpClient: httpClient).link();
    if (link == null) return const {};
    final client = CloudClient(
      baseUrl: link.baseUrl,
      signingSeed: (await _db.classSyncDao.identity()).signingSeed,
      client: httpClient?.call(),
    );
    try {
      return await HttpCloudSync(client).push(records);
    } finally {
      client.close();
    }
  }
}
