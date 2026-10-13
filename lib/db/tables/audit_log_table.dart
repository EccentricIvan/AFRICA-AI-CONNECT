import 'package:drift/drift.dart';

/// This device's audit log (schema 34): Admin and teacher actions that
/// change who may do what, and refusals. Append-only and hash-chained —
/// each row's [hash] covers the previous row's — and every row is signed by
/// the device key, so a row removed or edited later shows (`AuditLog.verify`).
///
/// Never holds PINs, codes, keys, tokens or anything a learner wrote.
@DataClassName('AuditEntry')
class AuditLog extends Table {
  @override
  String get tableName => 'audit_log';

  IntColumn get id => integer().autoIncrement()();

  /// ISO-8601 UTC, this device's clock.
  TextColumn get at => text()();

  /// Who acted: `admin`, `teacher:<id>`, `learner:<id>`, `device`.
  TextColumn get actor => text()();

  /// e.g. `teacher.added`, `device.revoked`, `cloud.enrolled`,
  /// `refused.pin`.
  TextColumn get action => text()();
  TextColumn get detail => text().withDefault(const Constant(''))();

  /// SHA-256 (hex) of the previous row's [hash] and this row's fields.
  TextColumn get hash => text()();

  /// The device key's Ed25519 signature over [hash] (base64url).
  TextColumn get sig => text()();
}
