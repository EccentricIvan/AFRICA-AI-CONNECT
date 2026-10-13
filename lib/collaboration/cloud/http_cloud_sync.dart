import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;

import '../sync/class_crypto.dart' show b64, signingPublicKey, unb64;
import 'cloud_sync.dart';

final _ed25519 = Ed25519();

/// A refusal or failure from the school cloud.
class CloudError implements Exception {
  const CloudError(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Talks to a school cloud (`backend/`, docs/CLOUD_API.md), signing every
/// request with this device's Ed25519 key — the same key P2P sync uses. It
/// holds no password or token: the server knows the device's school and
/// role from the key it enrolled.
class CloudClient {
  CloudClient({
    required this.baseUrl,
    required this.signingSeed,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _http = client ?? http.Client();

  /// e.g. `https://cloud.school.ug`, without a trailing slash.
  final String baseUrl;
  final String signingSeed;
  final Duration timeout;
  final http.Client _http;

  void close() => _http.close();

  /// [raw] lowercased, trimmed, without a trailing slash; null when it is
  /// not an http(s) address.
  static String? normalizeUrl(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (!t.contains('://')) t = 'https://$t';
    final uri = Uri.tryParse(t);
    if (uri == null ||
        !(uri.scheme == 'https' || uri.scheme == 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.replace(path: uri.path.replaceAll(RegExp(r'/+$'), '')).toString();
  }

  static List<int> signedBytes(
    String method,
    String path,
    String time,
    String nonce,
    List<int> body,
  ) => utf8.encode(
    [
      'otic-cloud-req-v1',
      method.toUpperCase(),
      path,
      time,
      nonce,
      crypto.sha256.convert(body).toString(),
    ].join('\n'),
  );

  Future<Map<String, String>> _headers(
    String method,
    String path,
    List<int> body,
  ) async {
    final pair = await _ed25519.newKeyPairFromSeed(unb64(signingSeed));
    final time = DateTime.now().toUtc().toIso8601String();
    final rnd = Random.secure();
    final nonce = b64(List<int>.generate(18, (_) => rnd.nextInt(256)));
    final sig = await _ed25519.sign(
      signedBytes(method, path, time, nonce, body),
      keyPair: pair,
    );
    return {
      'X-Otic-Device': await signingPublicKey(signingSeed),
      'X-Otic-Time': time,
      'X-Otic-Nonce': nonce,
      'X-Otic-Sig': b64(sig.bytes),
      'Content-Type': 'application/json',
    };
  }

  /// A signed request; the decoded JSON reply. Throws [CloudError] on any
  /// refusal (the server answers every refusal with the same 404).
  Future<Map<String, Object?>> signed(
    String method,
    String path, {
    Map<String, Object?>? json,
    List<int>? raw,
  }) async {
    final body = raw ?? (json == null ? <int>[] : utf8.encode(jsonEncode(json)));
    final uri = Uri.parse('$baseUrl$path');
    // Signed as the server sees it: the full path, with its query.
    final headers = await _headers(
      method,
      uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path,
      body,
    );
    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..bodyBytes = Uint8List.fromList(body);
    final response = await http.Response.fromStream(
      await _http.send(request).timeout(timeout),
    );
    return _decode(response);
  }

  /// Unsigned: enrollment, where the one-time code is the credential.
  Future<Map<String, Object?>> enroll({
    required String code,
    required String role,
    required String boxKey,
    String label = '',
  }) async {
    final response = await _http
        .post(
          Uri.parse('$baseUrl/v1/enroll'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'code': code.trim(),
            'device_key': await signingPublicKey(signingSeed),
            'box_key': boxKey,
            'role': role,
            'label': label,
          }),
        )
        .timeout(timeout);
    return _decode(response);
  }

  static Map<String, Object?> _decode(http.Response r) {
    if (r.statusCode == 200) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is Map<String, Object?>) return data;
      throw const CloudError('The school cloud sent something unexpected');
    }
    throw CloudError(switch (r.statusCode) {
      404 => 'Refused by the school cloud',
      429 => 'Too many tries — wait an hour',
      413 => 'Too large for the school cloud',
      _ => 'The school cloud answered ${r.statusCode}',
    }, status: r.statusCode);
  }
}

/// The cloud plug-in for a device enrolled in its school's cloud: sends the
/// outbox's records, signed. Each record id is stable, so a retry never
/// doubles anything.
class HttpCloudSync extends CloudSyncAdapter {
  HttpCloudSync(this.client);

  final CloudClient client;

  @override
  bool get enabled => true;

  @override
  Future<Set<String>> push(List<CloudRecord> records) async {
    final reply = await client.signed(
      'POST',
      '/v1/records',
      json: {
        'records': [
          for (final r in records)
            {'id': r.id, 'kind': r.kind, 'payload': r.payload},
        ],
      },
    );
    return {
      if (reply['accepted'] case final List ids)
        for (final id in ids)
          if (id is String) id,
    };
  }
}
