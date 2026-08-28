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
        AppLocale.rw: 'Nagira nte ngo ntangire ubucuruzi buto?',
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

    test('returns matched guidance before the general fallback', () async {
      final guidance = await service.getGuidance(
        'How do I avoid mobile money fraud?',
        AppLocale.en,
      );

      expect(guidance, contains('Never share your PIN'));
    });

    test(
      'returns localized fallback for an unknown offline question',
      () async {
        final guidance = await service.getGuidance(
          'What colour should I paint my room?',
          AppLocale.sw,
        );

        expect(guidance, await service.getFallback(AppLocale.sw));
        expect(guidance.toLowerCase(), isNot(contains('offline')));
      },
    );

    test(
      'falls back to the SALT corpus for a close phrase match outside the curated topics',
      () async {
        // A near-exact sentence from the SALT dev/test split, well outside
        // any curated intent topic (business/finance/health/etc).
        final match = await service.findMatch(
          'I want to go to town over the weekend.',
          AppLocale.lg,
        );

        expect(match, isNotNull);
        expect(match!.intentId, 'salt');
        expect(match.reply, contains('kibuga'));
      },
    );

    test('SALT tier is skipped for English (nothing to translate into)', () async {
      final match = await service.findMatch(
        'I want to go to town over the weekend.',
        AppLocale.en,
      );

      expect(match, isNull);
    });

    test('SALT tier is skipped for locales it has no data for', () async {
      final match = await service.findMatch(
        'I want to go to town over the weekend.',
        AppLocale.sw,
      );

      expect(match, isNull);
    });

    test('unknown questions stay constructive in every language', () async {
      for (final locale in AppLocale.values) {
        final guidance = await service.getGuidance(
          'xyzzy question outside the local topics',
          locale,
        );
        expect(guidance, isNotEmpty, reason: locale.name);
        expect(guidance.toLowerCase(), isNot(contains('api key')));
        expect(guidance.toLowerCase(), isNot(contains('not configured')));
      }
    });
  });
}
