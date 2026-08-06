class ApiConfig {
  ApiConfig._();

  static const groqKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const aiBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: '',
  );
}
