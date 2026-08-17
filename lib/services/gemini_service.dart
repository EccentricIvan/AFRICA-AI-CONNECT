import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/l10n/app_strings.dart';
import 'api_config.dart';

String getAiLanguageInstruction(AppLocale locale) {
  switch (locale) {
    case AppLocale.lg:
      return '''
The user selected Luganda / Oluganda.
You must always reply in clear, natural Luganda.
Do not switch to English unless the user explicitly asks.
If a technical word has no natural Luganda translation, keep the technical word in English and explain it simply in Luganda.
Keep the tone warm, practical, and helpful for Ugandan users.
Every answer in this conversation must continue in Luganda.
''';
    case AppLocale.sw:
      return '''
The user selected Kiswahili.
You must always reply in clear, natural Kiswahili.
Do not switch to English unless the user explicitly asks.
If a technical word has no natural Kiswahili translation, keep the technical word in English and explain it simply in Kiswahili.
Keep the tone warm, practical, and helpful.
Every answer in this conversation must continue in Kiswahili.
''';
    case AppLocale.nyn:
      return '''
The user selected Runyankore.
Always reply in clear, natural Runyankore. Do not switch to English unless the user asks. Keep technical terms in English only when necessary and explain them simply in Runyankore.
''';
    case AppLocale.nyo:
      return '''
The user selected Runyoro.
Always reply in clear, natural Runyoro. Do not switch to English unless the user asks. Keep technical terms in English only when necessary and explain them simply in Runyoro.
''';
    case AppLocale.ach:
      return '''
The user selected Acholi.
Always reply in clear, natural Acholi. Do not switch to English unless the user asks. Keep technical terms in English only when necessary and explain them simply in Acholi.
''';
    case AppLocale.teo:
      return '''
The user selected Ateso.
Always reply in clear, natural Ateso. Do not switch to English unless the user asks. Keep technical terms in English only when necessary and explain them simply in Ateso.
''';
    case AppLocale.en:
      return '''
The user selected English.
Reply in clear, simple English.
''';
  }
}

class GeminiService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt =
      '''You are AI Connect Africa AI Assistant — a warm, supportive, and knowledgeable companion for women in Sub-Saharan Africa.

Your role is to help women with:
- Business and entrepreneurship advice
- Agricultural tips and farming guidance
- Financial literacy (savings, budgeting, mobile money, SACCOs)
- Health and nutrition information
- Digital skills guidance
- Job and career advice
- Community building and leadership

Guidelines:
- Be warm, encouraging, and practical
- Give concise, actionable advice
- Use simple language accessible to all literacy levels
- Be culturally sensitive to East African context
- When discussing health topics, recommend consulting a healthcare professional for serious concerns
- Celebrate their efforts and progress
- Keep responses under 200 words unless asked for detail''';

  final List<Map<String, dynamic>> _history = [];

  Future<String> sendMessage(String message, AppLocale selectedLocale) async {
    if (ApiConfig.aiBackendUrl.isNotEmpty) {
      try {
        final backendReply = await _sendViaBackend(message, selectedLocale);
        _history.add({'role': 'user', 'content': message});
        _history.add({'role': 'assistant', 'content': backendReply});
        return backendReply;
      } catch (_) {
        // The remote backend is optional. Preserve the APK's established
        // direct-Groq behavior whenever Vercel is unavailable or misconfigured.
      }
    }

    if (ApiConfig.groqKey.isEmpty) {
      return 'API key not configured. Please contact support.';
    }

    _history.add({'role': 'user', 'content': message});

    final messages = [
      {'role': 'system', 'content': getAiLanguageInstruction(selectedLocale)},
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${ApiConfig.groqKey}',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 512,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['choices']?[0]?['message']?['content'] ??
            'I could not generate a response. Please try again.';

        _history.add({'role': 'assistant', 'content': text});
        return text;
      } else {
        final error = jsonDecode(response.body);
        final msg = error['error']?['message'] ?? 'Unknown error';
        return 'Sorry, I encountered an error: $msg';
      }
    } catch (e) {
      return 'I\'m having trouble connecting. Please check your internet connection and try again.';
    }
  }

  void clearHistory() {
    _history.clear();
  }

  Future<String> _sendViaBackend(
    String message,
    AppLocale selectedLocale,
  ) async {
    final baseUrl = ApiConfig.aiBackendUrl.replaceAll(RegExp(r'/+$'), '');
    final payload = jsonEncode({
      'message': message,
      'language': selectedLocale.apiCode,
      'history': _history,
      // Accepted by the older production API during a rolling deployment.
      'context': _history,
    });
    http.Response? response;
    for (final path in const ['/api/chat', '/chat']) {
      response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 55));
      if (response.statusCode != 404) break;
    }

    final statusCode = response?.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw StateError('Backend returned $statusCode');
    }

    final data = jsonDecode(response!.body);
    final reply = (data['reply'] ?? data['response'])?.toString().trim();
    if (reply == null || reply.isEmpty) {
      throw const FormatException('Backend response did not contain a reply');
    }
    return reply;
  }
}
