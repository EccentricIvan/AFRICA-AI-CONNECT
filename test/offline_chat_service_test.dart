import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';
import 'package:otic_connect/db/database.dart';
import 'package:otic_connect/services/offline_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineChatService', () {
    // In-memory database, migrated (and seeded from offline_chat.json) like
    // any real install — the curated tier now lives in Drift, not JSON.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final service = OfflineChatService(db.chatContentDao);

    tearDownAll(() => db.close());

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

    test(
      'a content-pack style upsert adds a new intent findMatch can reach',
      () async {
        await db.chatContentDao.upsertIntent(
          intentKey: 'content_pack_test',
          category: 'test_category',
          patternsByLocale: {
            'en': ['a brand new content pack topic'],
          },
          variantsByLocale: {
            'en': ['A brand new content pack reply.'],
          },
        );

        final match = await service.findMatch(
          'a brand new content pack topic',
          AppLocale.en,
        );

        expect(match?.intentId, 'content_pack_test');
        expect(match?.category, 'test_category');
        expect(match?.reply, 'A brand new content pack reply.');
      },
    );

    test(
      're-upserting the same intent does not duplicate an existing variant',
      () async {
        const variants = {
          'en': ['Same variant text every time.'],
        };
        for (var i = 0; i < 3; i++) {
          await db.chatContentDao.upsertIntent(
            intentKey: 'dedup_test',
            category: 'test_category',
            patternsByLocale: {
              'en': ['dedup test pattern'],
            },
            variantsByLocale: variants,
          );
        }

        final rows = await (db.select(
          db.chatResponseVariants,
        )..where((v) => v.intentKey.equals('dedup_test'))).get();
        expect(rows, hasLength(1));
      },
    );

    test(
      'picks a different variant on successive replies once more than one exists',
      () async {
        await db.chatContentDao.upsertIntent(
          intentKey: 'variant_rotation_test',
          category: 'test_category',
          patternsByLocale: {
            'en': ['rotation test pattern'],
          },
          variantsByLocale: {
            'en': ['Rotation reply A.', 'Rotation reply B.'],
          },
        );

        final first = await service.findMatch(
          'rotation test pattern',
          AppLocale.en,
        );
        final second = await service.findMatch(
          'rotation test pattern',
          AppLocale.en,
        );

        expect({first?.reply, second?.reply}, {
          'Rotation reply A.',
          'Rotation reply B.',
        });
      },
    );

    test(
      'an ambiguous match is nudged toward the prior turn\'s category',
      () async {
        const query =
            'please can someone assist me with this urgent problem';

        await db.chatContentDao.upsertIntent(
          intentKey: 'context_test_alpha',
          category: 'category_alpha',
          patternsByLocale: {
            'en': ['with this urgent assist me'],
          },
          variantsByLocale: {
            'en': ['Alpha reply text.'],
          },
        );
        await db.chatContentDao.upsertIntent(
          intentKey: 'context_test_beta',
          category: 'category_beta',
          patternsByLocale: {
            'en': ['today problem this with me assist'],
          },
          variantsByLocale: {
            'en': ['Beta reply text.'],
          },
        );

        final withoutContext = await service.findMatch(query, AppLocale.en);
        expect(withoutContext?.intentId, 'context_test_alpha');

        final withContext = await service.findMatch(
          query,
          AppLocale.en,
          priorCategory: 'category_beta',
        );
        expect(withContext?.intentId, 'context_test_beta');
      },
    );
  });
}
