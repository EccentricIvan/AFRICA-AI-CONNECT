import 'dart:io';

import 'package:ai_connect_africa/ai_core/model/model_locations.dart';
import 'package:ai_connect_africa/ai_core/model/model_manager.dart';
import 'package:ai_connect_africa/ai_core/translate/afrislm_model_manager.dart';
import 'package:ai_connect_africa/services/model_fetch_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<void> _writeGgufStub(File fixture, int bytes) async {
  await fixture.parent.create(recursive: true);
  final raf = await fixture.open(mode: FileMode.write);
  await raf.writeFrom(const [0x47, 0x47, 0x55, 0x46]);
  await raf.truncate(bytes);
  await raf.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const fixtureBytes = 320 * 1024 * 1024;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });
  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Install Packages Q4 name is the AfriSLM canonical file', () {
    expect(AfriSlmModelManager.modelFileName, ModelFetchFiles.translate);
    expect(
      AfriSlmModelManager.allFileNames,
      contains('translate-afrislm.gguf'),
    );
  });

  test('candidate list includes Documents/OTIC and repo models/', () async {
    const name = 'afrislm-0.8b-q4_k_m.gguf';
    final files = await modelCandidateFiles(name);
    expect(
      files.any((f) => f.contains('Documents') && f.contains('OTIC')),
      isTrue,
    );
    expect(
      files.any((f) => f.contains('${p.separator}models${p.separator}')),
      isTrue,
    );
  });

  for (final name in [
    AfriSlmModelManager.ggufFileName,
    'translate-afrislm.gguf',
  ]) {
    test('AfriSLM manager discovers $name without installed models', () async {
      final root = await Directory.systemTemp.createTemp('otic-discovery-');
      addTearDown(() => root.delete(recursive: true));
      final fixture = File(p.join(root.path, 'models', name));
      await _writeGgufStub(fixture, fixtureBytes);
      final requestedNames = <String>[];
      final manager = AfriSlmModelManager(
        candidateFiles: (fileName) async {
          requestedNames.add(fileName);
          return [p.join(root.path, 'models', fileName)];
        },
      );

      final info = await manager.checkModel();
      expect(info.isReady, isTrue, reason: '${info.status} ${info.path}');
      expect(info.path, fixture.path);
      expect(info.sizeBytes, fixtureBytes);
      expect(requestedNames, contains(name));
    });
  }

  test('the brain manager finds the coder GGUF, not AfriSLM', () async {
    final fixture = File(
      p.join(Directory.current.path, 'models', ModelManager.brainGgufFileName),
    );
    final hadFixture = await fixture.exists();
    if (!hadFixture) {
      // Above the brain's 400 MB truncation floor.
      await _writeGgufStub(fixture, 420 * 1024 * 1024);
      addTearDown(() async {
        if (await fixture.exists()) await fixture.delete();
      });
    }

    final info = await ModelManager().checkModel();
    expect(info.isReady, isTrue, reason: '${info.status} ${info.path}');
    expect(info.path!.toLowerCase(), contains('coder-1.5b'));
    expect(info.path!.toLowerCase().contains('afrislm'), isFalse);
  });
}
