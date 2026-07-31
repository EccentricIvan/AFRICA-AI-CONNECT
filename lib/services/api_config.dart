class ApiConfig {
  ApiConfig._();

  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String get chatUrl =>
      '${backendBaseUrl.replaceAll(RegExp(r'/+$'), '')}/chat';
}
