import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// Static chrome for the East African core set (plus English).
///
/// Full 19-language tables live in [kUiStrings] / [kUiStringsMore]. This
/// registry is the small, typed surface for titles, the composer, and the
/// offline chip so a language flip updates labels in the same frame as
/// [appLanguageProvider] redirects the chat stream.
class UiRegistry {
  const UiRegistry._();

  static const appTitle = 'AI Connect Africa';
  static const askPlaceholder = 'Ask AI anything...';
  static const listening = 'Listening… speak now';
  static const newSession = 'New session';
  static const offline = '100% offline — no internet required';
  static const offlineChip = 'Offline mode';
  static const send = 'Send';
  static const learn = 'Learn';

  static String label(BuildContext context, String english) =>
      tr(context, english);
}
