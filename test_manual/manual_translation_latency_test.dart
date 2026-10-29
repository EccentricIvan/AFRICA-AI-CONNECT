// Measures what a translation call actually costs, so latency work targets
// the real bottleneck instead of the one the comments assume.
//
// The question it answers: llama_cpp_engine.dart says llm_llamacpp reloads
// the ~670 MB GGUF on *every* request (the helper isolate frees it in a
// finally). If that is true, call 2 costs about what call 1 costs and the
// reload dominates every turn — and splitting a reply into N streamed
// chunks would multiply that cost by N. If call 2 is much cheaper, the
// isolate is caching and chunked streaming is close to free.
//
// Needs the real translate-afrislm.gguf on disk. Lives outside test/ so
// `flutter test` and CI never pick it up.
//   flutter test test_manual/manual_translation_latency_test.dart
import 'dart:io';

import 'package:ai_connect_africa/ai_core/inference/llama_cpp_engine.dart';
import 'package:ai_connect_africa/ai_core/translate/translation_pipeline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sentences = [
  'Photosynthesis is how a plant makes food from sunlight.',
  'The leaf takes in carbon dioxide through tiny holes called stomata.',
  'Water travels up from the roots to reach the leaf.',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  SharedPreferences.setMockInitialValues({});
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler(
          (MethodCall call) async => Directory.systemTemp.path);

  test('per-call translation cost', () async {
    const candidates = [
      r'dist\models\translate-afrislm.gguf',
      r'C:\Users\esian\OneDrive\Documents\OTIC\translate-afrislm.gguf',
      r'build\windows\x64\runner\Release\models\translate-afrislm.gguf',
    ];
    final modelPath = candidates.firstWhere((p) => File(p).existsSync(),
        orElse: () => candidates.first);
    stdout.writeln('Model: $modelPath '
        '(${(File(modelPath).lengthSync() / (1024 * 1024)).round()} MB)');

    final engine = LlamaCppEngineImpl();
    final loadStart = DateTime.now();
    await engine.loadModel(modelPath);
    stdout.writeln('loadModel(): '
        '${DateTime.now().difference(loadStart).inMilliseconds} ms '
        '(path only — the GGUF is read inside the helper isolate)');

    final pipeline = TranslationPipeline(engine);
    final timings = <int>[];

    stdout.writeln('\n--- three sequential English -> Swahili calls ---');
    for (var i = 0; i < _sentences.length; i++) {
      final started = DateTime.now();
      final out = await pipeline.fromEnglish(_sentences[i], 'sw');
      final ms = DateTime.now().difference(started).inMilliseconds;
      timings.add(ms);
      stdout.writeln('call ${i + 1}: ${ms} ms  ->  $out');
    }

    // Same text twice in a row: identical work, so any drop between them is
    // caching in the runtime, not a shorter prompt.
    stdout.writeln('\n--- same sentence repeated ---');
    for (var i = 0; i < 2; i++) {
      final started = DateTime.now();
      await pipeline.fromEnglish(_sentences[0], 'sw');
      stdout.writeln(
          'repeat ${i + 1}: ${DateTime.now().difference(started).inMilliseconds} ms');
    }

    final first = timings.first;
    final rest = timings.skip(1).toList();
    final restAvg = rest.reduce((a, b) => a + b) / rest.length;
    stdout.writeln('\nfirst call: $first ms');
    stdout.writeln('later calls: ${restAvg.round()} ms average');
    final ratio = restAvg / first;
    stdout.writeln('later/first ratio: ${ratio.toStringAsFixed(2)}');
    stdout.writeln(ratio > 0.6
        ? 'VERDICT: per-call reload is REAL — fix residency before chunking a '
            'reply into N streamed calls, or total turn time gets N times worse.'
        : 'VERDICT: later calls are much cheaper — the runtime is caching the '
            'model, so chunked streaming is close to free.');

    await engine.dispose();
    expect(timings, hasLength(_sentences.length));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
