import 'package:ai_connect_africa/ai_core/translate/supported_languages.dart';
import 'package:ai_connect_africa/l10n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kirundi uses Kinyarwanda on the AfriSLM prompt', () {
    expect(languageName('rn'), 'Kirundi');
    expect(languagePromptName('rn'), 'Kinyarwanda');
    expect(hasUiString('rn', 'Learn'), isTrue);
    expect(hasUiString('sw', 'Ask AI anything...'), isTrue);
    expect(hasUiString('lg', 'Ask AI anything...'), isTrue);
    expect(hasUiString('rw', 'Ask AI anything...'), isTrue);
  });
}
