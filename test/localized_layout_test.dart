import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';
import 'package:otic_connect/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding does not overflow on a small phone in any locale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in AppLocale.values) {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(locale.name),
          overrides: [
            localeProvider.overrideWith(
              (ref) => LocaleNotifier()..loadFromPrefs(locale.name),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow on language page for ${locale.name}',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow on welcome page for ${locale.name}',
      );
    }
  });
}
