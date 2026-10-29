// Controlled A/B of the translation prompt format, against a *fixed* English
// source so the only variable is the prompt.
//
// The round-trip smoke test cannot answer this: its English text comes out of
// the chat model at temperature 0.4, so it differs run to run and any quality
// change is unattributable.
//
// A = the old bare prompt, no system turn.
// B = the format TranslatePsy-AfriSLM's model card documents.
//
// Lives outside test/ so `flutter test` (and CI) never picks it up.
// Needs translate-afrislm.gguf on disk, and on Windows needs vulkan-1.dll
// reachable (see tools/fetch_vulkan_loader.ps1).
//   flutter test test_manual/manual_prompt_format_ab_test.dart
import 'dart:io';

import 'package:ai_connect_africa/ai_core/inference/llama_cpp_engine.dart';
import 'package:ai_connect_africa/ai_core/translate/translation_pipeline.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Terms whose mistranslation is the failure we actually care about: a
/// curriculum word rendered as a literal gloss rather than the subject term.
const _watchTerms = ['photosynthesis', 'algae', 'chemical energy'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  SharedPreferences.setMockInitialValues({});
  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler(
          (MethodCall call) async => Directory.systemTemp.path);

  test('old vs trained prompt format on identical English input', () async {
    final candidates = [
      r'C:\Users\esian\otic-studio-v3\dist\models\translate-afrislm.gguf',
      r'C:\Users\esian\OneDrive\Documents\OTIC\translate-afrislm.gguf',
    ];
    final path = candidates.firstWhere(
      (p) => File(p).existsSync(),
      orElse: () => candidates.first,
    );
    stdout.writeln('Translate model: $path');

    // Fixed, and deliberately curriculum-shaped.
    const english =
        'Photosynthesis is the process by which plants, algae and some '
        'bacteria convert light energy into chemical energy. It is important '
        'because it produces oxygen and supports life on Earth.';

    final engine = LlamaCppEngineImpl();
    await engine.loadModel(path);

    // ── A: the old bare prompt, reproduced exactly as it used to be built.
    final rawA = await engine.generate(
      prompt: 'Translate to Swahili. Output the translation only.\n\n$english',
      maxTokens: 512,
      temperature: 0.0,
    );

    // ── B: the current pipeline, i.e. the model card's format.
    final pipeline = TranslationPipeline(engine);
    final b = await pipeline.fromEnglish(english, 'sw');

    stdout.writeln('\n================ SOURCE (en) ================');
    stdout.writeln(english);
    stdout.writeln('\n================ A: old bare prompt ================');
    stdout.writeln(rawA.trim());
    stdout.writeln('\n================ B: trained format ================');
    stdout.writeln(b.trim());

    stdout.writeln('\n================ CHECKS ================');
    for (final label in ['A', 'B']) {
      final text = (label == 'A' ? rawA : b).toLowerCase();
      final leftInEnglish =
          _watchTerms.where((t) => text.contains(t.toLowerCase())).toList();
      // Instruction echo: the model repeating its own brief back at us.
      final echoes = [
        'translate',
        'translation:',
        'you are a professional',
      ].where(text.contains).toList();
      stdout.writeln(
        '$label: chars=${text.length} '
        'untranslated_terms=$leftInEnglish instruction_echo=$echoes',
      );
    }

    expect(b.trim(), isNotEmpty);
    await engine.dispose();
  }, timeout: const Timeout(Duration(minutes: 15)));
}
