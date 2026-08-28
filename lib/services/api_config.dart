class ApiConfig {
  static const String _groqKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String _chatBackendUrl = String.fromEnvironment(
    'CHAT_BACKEND_URL',
    defaultValue: '',
  );
  static const String _aiBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: '',
  );
  static const String _aiChatEndpoint = String.fromEnvironment(
    'AI_CHAT_ENDPOINT',
    defaultValue: '',
  );

  static String get groqKey => _groqKey.trim();

  static String get chatBackendUrl => _chatBackendUrl.trim();
  static String get aiBackendUrl => _aiBackendUrl.trim();
  static String get aiChatEndpoint => _aiChatEndpoint.trim();

  static Uri? get chatBackendUri {
    final explicitEndpoint = _validatedUri(aiChatEndpoint);
    if (explicitEndpoint != null) return explicitEndpoint;

    final legacyEndpoint = _validatedUri(chatBackendUrl);
    if (legacyEndpoint != null) return legacyEndpoint;

    final backendBase = _validatedUri(aiBackendUrl);
    if (backendBase == null) return null;

    final path =
        backendBase.path.endsWith('/chat')
            ? backendBase.path
            : '${backendBase.path.replaceFirst(RegExp(r'/$'), '')}/chat';
    return backendBase.replace(path: path);
  }

  static Uri? _validatedUri(String value) {
    if (value.isEmpty ||
        value.contains('YOUR_BACKEND_URL') ||
        value.contains('TODO') ||
        value.contains('PASTE')) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

    return uri;
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
