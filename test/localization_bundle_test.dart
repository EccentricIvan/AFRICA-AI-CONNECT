import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every local language has the complete user-visible catalog', () async {
    await S.loadBundledTranslations();

    for (final locale in AppLocale.values.where((item) => item != AppLocale.en)) {
      for (final key in S.catalogKeys) {
        final localized = S.trFromLocale(key, locale).trim();
        expect(localized, isNotEmpty, reason: '$key is empty for ${locale.name}');
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
