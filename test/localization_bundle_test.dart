import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every local language has complete visible chat and navigation text', () async {
    await S.loadBundledTranslations();

    const visibleKeys = [
      'home',
      'learn',
      'market',
      'community',
      'chat',
      'chat_assistant_title',
      'app_powered_by',
      'new_chat',
      'ask_anything',
      'topic_business_q',
      'topic_savings_q',
    ];

    for (final locale in AppLocale.values.where((item) => item != AppLocale.en)) {
      for (final key in visibleKeys) {
        final localized = S.trFromLocale(key, locale).trim();
        expect(localized, isNotEmpty, reason: '$key is empty for ${locale.name}');
        expect(
          localized,
          isNot(S.trFromLocale(key, AppLocale.en)),
          reason: '$key fell back to English for ${locale.name}',
        );
      }
      expect(
        S.trFromLocale('app_powered_by', locale).toLowerCase(),
        isNot(contains('groq')),
      );
      expect(
        S.trFromLocale('app_powered_by', locale).toLowerCase(),
        isNot(contains('llama')),
      );
    }
  });
}
