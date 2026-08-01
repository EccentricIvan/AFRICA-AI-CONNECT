import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';

void main() {
  test('Luganda navigation and chat interface are localized', () {
    expect(S.trFromLocale('home', AppLocale.lg), 'Awaka');
    expect(S.trFromLocale('learn', AppLocale.lg), 'Yiga');
    expect(S.trFromLocale('market', AppLocale.lg), 'Akatale');
    expect(S.trFromLocale('community', AppLocale.lg), 'Abantu');
    expect(S.trFromLocale('chat', AppLocale.lg), 'Emboozi');
    for (final key in _chatKeys) {
      expect(S.trFromLocale(key, AppLocale.lg), isNot(S.trFromLocale(key, AppLocale.en)));
    }
  });

  test('Kiswahili navigation and chat interface are localized', () {
    expect(S.trFromLocale('home', AppLocale.sw), 'Mwanzo');
    expect(S.trFromLocale('learn', AppLocale.sw), 'Jifunze');
    expect(S.trFromLocale('market', AppLocale.sw), 'Soko');
    expect(S.trFromLocale('community', AppLocale.sw), 'Jamii');
    expect(S.trFromLocale('chat', AppLocale.sw), 'Gumzo');
    for (final key in _chatKeys) {
      expect(S.trFromLocale(key, AppLocale.sw), isNot(S.trFromLocale(key, AppLocale.en)));
    }
  });

  test('saved locale is restored before rendering', () {
    expect(LocaleNotifier.fromSaved('lg'), AppLocale.lg);
    expect(LocaleNotifier.fromSaved('sw'), AppLocale.sw);
    expect(LocaleNotifier.fromSaved(null), AppLocale.en);
  });

  test('additional Sunflower languages can be selected and restored', () {
    expect(LocaleNotifier.fromSaved('nyn'), AppLocale.nyn);
    expect(LocaleNotifier.fromSaved('teo'), AppLocale.teo);
    expect(LocaleNotifier.fromSaved('nyo'), AppLocale.nyo);
    expect(LocaleNotifier.fromSaved('ach'), AppLocale.ach);
    expect(LocaleNotifier.fromSaved('laj'), AppLocale.laj);
  });
}

const _chatKeys = [
  'app_powered_by',
  'new_chat',
  'ask_anything',
  'thinking',
  'chat_retry',
  'chat_connection_error',
  'chat_offline_error',
  'ai_greeting',
  'topic_business_q',
  'topic_savings_q',
];
