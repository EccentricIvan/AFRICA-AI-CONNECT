import 'dart:convert';
import 'dart:io';

import 'package:ai_connect_africa/ai_core/model/model_download_service.dart';
import 'package:ai_connect_africa/ai_core/model/model_package.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves [body] over loopback, honouring Range so resume can be exercised
/// for real rather than mocked. [rangeAware] false simulates a server that
/// ignores Range and replies 200 with the whole file.
class _FakeAssetServer {
  _FakeAssetServer(this.body, {this.rangeAware = true});

  final List<int> body;
  final bool rangeAware;
  late final HttpServer _server;
  final List<String> rangeHeaders = [];

  /// Bytes served in total, to prove a resume did not re-send the prefix.
  int servedBytes = 0;

  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final range = req.headers.value(HttpHeaders.rangeHeader);
      if (range != null) rangeHeaders.add(range);

      var start = 0;
      if (range != null && rangeAware) {
        start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
        req.response.statusCode = HttpStatus.partialContent;
      }
      final slice = body.sublist(start);
      servedBytes += slice.length;
      req.response.headers.contentType = ContentType.binary;
      req.response.contentLength = slice.length;
      req.response.add(slice);
      await req.response.close();
    });
    return 'http://${_server.address.address}:${_server.port}/model.bin';
  }

  Future<void> stop() => _server.close(force: true);
}

ModelPackage _pkg(String url, List<int> body) => ModelPackage(
      id: 'chat',
      label: 'Tutor model',
      fileName: 'model.bin',
      url: url,
      sha256: sha256.convert(body).toString(),
      approxBytes: body.length,
      essential: true,
    );

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('model_dl_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  final body = utf8.encode('x' * 40000);

  test('downloads, verifies the digest, and renames off .part', () async {
    final server = _FakeAssetServer(body);
    final url = await server.start();
    addTearDown(server.stop);

    final target = '${tmp.path}/model.bin';
    final path = await ModelDownloadService()
        .download(_pkg(url, body), targetPath: target);

    expect(path, target);
    expect(await File(target).readAsBytes(), body);
    expect(await File('$target.part').exists(), isFalse,
        reason: 'the .part file must not survive a successful download');
  });

  test('resumes from an existing .part instead of refetching it', () async {
    final server = _FakeAssetServer(body);
    final url = await server.start();
    addTearDown(server.stop);

    final target = '${tmp.path}/model.bin';
    // A previous attempt that died 15000 bytes in.
    await File('$target.part').writeAsBytes(body.sublist(0, 15000));

    await ModelDownloadService().download(_pkg(url, body), targetPath: target);

    expect(server.rangeHeaders, ['bytes=15000-']);
    expect(server.servedBytes, body.length - 15000,
        reason: 'the already-downloaded prefix must not be sent again');
    // The digest has to cover the replayed prefix too, or this would throw.
    expect(await File(target).readAsBytes(), body);
  });

  test('starts over when the server ignores the Range request', () async {
    final server = _FakeAssetServer(body, rangeAware: false);
    final url = await server.start();
    addTearDown(server.stop);

    final target = '${tmp.path}/model.bin';
    await File('$target.part').writeAsBytes(body.sublist(0, 15000));

    await ModelDownloadService().download(_pkg(url, body), targetPath: target);

    // Appending the full body onto the stale prefix would corrupt the file;
    // it must be discarded instead.
    expect(await File(target).readAsBytes(), body);
  });

  test('deletes the .part when the digest does not match', () async {
    final server = _FakeAssetServer(body);
    final url = await server.start();
    addTearDown(server.stop);

    final target = '${tmp.path}/model.bin';
    final wrong = ModelPackage(
      id: 'chat',
      label: 'Tutor model',
      fileName: 'model.bin',
      url: url,
      sha256: 'deadbeef' * 8,
      approxBytes: body.length,
      essential: true,
    );

    await expectLater(
      ModelDownloadService().download(wrong, targetPath: target),
      throwsA(isA<ModelDownloadException>()),
    );

    expect(await File(target).exists(), isFalse);
    expect(await File('$target.part').exists(), isFalse,
        reason: 'corrupt bytes must not be left for a later resume to append to');
  });

  test('reports failure state rather than throwing raw HTTP errors', () async {
    final server = HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final s = await server;
    s.listen((req) async {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
    });
    addTearDown(() => s.close(force: true));

    final url = 'http://${s.address.address}:${s.port}/missing.bin';
    final states = <ModelDownloadState>[];

    await expectLater(
      ModelDownloadService().download(
        _pkg(url, body),
        targetPath: '${tmp.path}/model.bin',
        onState: states.add,
      ),
      throwsA(isA<ModelDownloadException>()),
    );

    expect(states.last.phase, DownloadPhase.failed);
    expect(states.last.error, contains('404'));
  });
}
