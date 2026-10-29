import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/class_crypto.dart' show b64, unb64;
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';

final _ed25519 = Ed25519();

/// Longest detail kept per row.
const kAuditDetailChars = 200;

/// This device's signed, hash-chained audit log (`audit_log`, schema 34):
/// who changed teachers, classes, subjects, assignments, learners, devices
/// and the school cloud, and refusals.
///
/// It records that something happened, never secrets or learners' words:
/// callers pass names and ids only — never PINs, codes, keys or answers.
/// Each row's hash covers the one before it and is signed by the device
/// key, so [verify] finds a row deleted, edited or inserted afterwards by
/// anyone without that key. Someone holding the device's database (and so
/// its key) could rewrite the whole chain; encryption at rest and sending
/// the log to the school cloud are what limit that.
class AuditLogService {
  AuditLogService(this._db);

  final OticDatabase _db;

  static String _hash(
    String previous,
    String at,
    String actor,
    String action,
    String detail,
  ) => crypto.sha256
      .convert(utf8.encode('otic-audit-v1\n$previous\n$at\n$actor\n$action\n$detail'))
      .toString();

  /// Appends one row. Best-effort: a failure is logged, never thrown, so an
  /// audit problem can't stop the action it records.
  Future<void> record(String actor, String action, {String detail = ''}) async {
    try {
      final seed = (await _db.classSyncDao.identity()).signingSeed;
      final pair = await _ed25519.newKeyPairFromSeed(unb64(seed));
      await _db.transaction(() async {
        final last =
            await (_db.select(_db.auditLog)
                  ..orderBy([(t) => OrderingTerm.desc(t.id)])
                  ..limit(1))
                .getSingleOrNull();
        final at = DateTime.now().toUtc().toIso8601String();
        final clipped = detail.length > kAuditDetailChars
            ? detail.substring(0, kAuditDetailChars)
            : detail;
        final hash = _hash(last?.hash ?? '', at, actor, action, clipped);
        final sig = await _ed25519.sign(utf8.encode(hash), keyPair: pair);
        await _db
            .into(_db.auditLog)
            .insert(
              AuditLogCompanion.insert(
                at: at,
                actor: actor,
                action: action,
                detail: Value(clipped),
                hash: hash,
                sig: b64(sig.bytes),
              ),
            );
      });
    } catch (e) {
      debugPrint('Audit log: not recorded ($e)');
    }
  }

  /// Null when every row chains and is signed by this device; otherwise
  /// the id of the first row that doesn't.
  Future<int?> verify() async {
    final seed = (await _db.classSyncDao.identity()).signingSeed;
    final pair = await _ed25519.newKeyPairFromSeed(unb64(seed));
    final key = await pair.extractPublicKey();
    var previous = '';
    for (final r in await (_db.select(
      _db.auditLog,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get()) {
      final expected = _hash(previous, r.at, r.actor, r.action, r.detail);
      if (expected != r.hash) return r.id;
      final ok = await _ed25519.verify(
        utf8.encode(r.hash),
        signature: Signature(unb64(r.sig), publicKey: key),
      );
      if (!ok) return r.id;
      previous = r.hash;
    }
    return null;
  }

  /// The latest [limit] rows, newest first.
  Stream<List<AuditEntry>> watchRecent({int limit = 100}) =>
      (_db.select(_db.auditLog)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(limit))
          .watch();
}

final auditLogProvider = Provider<AuditLogService>(
  (ref) => AuditLogService(ref.watch(dbProvider)),
);
