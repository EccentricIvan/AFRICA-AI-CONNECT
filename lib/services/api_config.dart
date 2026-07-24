class ApiConfig {
  static const String _groqKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String _chatBackendUrl = String.fromEnvironment(
    'CHAT_BACKEND_URL',
    defaultValue: '',
  );

  static String get groqKey => _groqKey.trim();

  static String get chatBackendUrl => _chatBackendUrl.trim();

  static Uri? get chatBackendUri {
    final value = chatBackendUrl;

    if (value.isEmpty ||
        value.contains('YOUR_BACKEND_URL') ||
        value.contains('TODO') ||
        value.contains('PASTE')) {
      return null;
    }

    return Uri.tryParse(value);
  }

  static bool get hasGroqKey {
    final key = groqKey;

    return key.isNotEmpty &&
        !key.contains('YOUR_API_KEY') &&
        !key.contains('TODO') &&
        !key.contains('PASTE');
  }

  static bool get hasChatBackend => chatBackendUri != null;

  static bool get hasOnlineAiConfig => hasGroqKey || hasChatBackend;
}
