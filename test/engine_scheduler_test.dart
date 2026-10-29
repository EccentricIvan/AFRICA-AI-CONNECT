import 'package:ai_connect_africa/ai_core/inference/engine_scheduler.dart';
import 'package:ai_connect_africa/ai_core/inference/pinned_prompt_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EngineScheduler runs jobs one at a time', () async {
    final order = <int>[];
    final first = EngineScheduler.instance.exclusive(() async {
      order.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      order.add(2);
      return 1;
    });
    final second = EngineScheduler.instance.exclusive(() async {
      order.add(3);
      return 2;
    });
    await Future.wait([first, second]);
    expect(order, [1, 2, 3]);
  });

  test('PinnedPromptCache interns identical system prompts', () {
    const a = 'Translate the following text from English to Swahili.';
    const b = 'Translate the following text from English to Swahili.';
    expect(identical(PinnedPromptCache.intern(a), PinnedPromptCache.intern(b)),
        isTrue);
  });
}
