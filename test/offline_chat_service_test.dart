import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';
import 'package:otic_connect/services/offline_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineChatService', () {
    final service = OfflineChatService();

    test('finds a localized answer in every supported language', () async {
      final questions = <AppLocale, String>{
        AppLocale.en: 'How do I start a small business?',
        AppLocale.lg: 'Ntandika ntya obusubuzi obutono?',
        AppLocale.sw: 'Ninaanzaje biashara ndogo?',
        AppLocale.nyn: 'Nintandika nta obushuubuzi bukye?',
        AppLocale.nyo: 'Ntandika nta obusuubuzi obutaito?',
        AppLocale.ach: 'Acako nining cato wil matidi?',
        AppLocale.teo: 'Acakar biai aduka na edit?',
      };

      for (final entry in questions.entries) {
        final match = await service.findMatch(entry.value, entry.key);
        expect(match, isNotNull, reason: 'No match for ${entry.key.name}');
        expect(match!.intentId, 'business_start');
        expect(match.reply, isNotEmpty);
      }
    });

    test('uses ranked token matching for a reworded question', () async {
      final match = await service.findMatch(
        'Please help me with saving money tips',
        AppLocale.en,
      );

      expect(match?.intentId, 'budget_and_save');
    });

    test('does not return an unrelated low-confidence answer', () async {
      final match = await service.findMatch(
        'What colour should I paint my room?',
        AppLocale.en,
      );

      expect(match, isNull);
    });

    test('has a fallback in every supported language', () async {
      for (final locale in AppLocale.values) {
        expect(await service.getFallback(locale), isNotEmpty);
      }
    });
  });
}
