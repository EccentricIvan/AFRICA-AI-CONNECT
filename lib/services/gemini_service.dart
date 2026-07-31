import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/l10n/app_strings.dart';
import 'api_config.dart';

/// OTIC backend chat client. Provider secrets remain on the FastAPI server.
class GeminiService {
  final List<Map<String, String>> _history = [];

  String _languageCode(AppLocale locale) {
    switch (locale) {
      case AppLocale.lg:
        return 'lug';
      case AppLocale.sw:
        return 'swa';
      case AppLocale.en:
        return 'eng';
    }
  }

  Future<String> sendMessage(String message, AppLocale selectedLocale) async {
    if (ApiConfig.backendBaseUrl.isEmpty) {
      return 'Backend URL not configured. Please contact support.';
    }

    final context = _history
        .map((item) => {
              'role': item['role'],
              'content': item['content'],
            })
        .toList(growable: false);
    _history.add({'role': 'user', 'content': message});

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.chatUrl),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'language': _languageCode(selectedLocale),
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 100));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final text = data['response'];
        if (text is String && text.trim().isNotEmpty) {
          _history.add({'role': 'assistant', 'content': text.trim()});
          return text.trim();
        }
      }

      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      return detail is String
          ? 'Sorry, the assistant is unavailable: $detail'
          : 'Sorry, the assistant is temporarily unavailable.';
    } on FormatException {
      return 'The server returned an invalid response. Please try again.';
    } catch (_) {
      return 'I\'m having trouble connecting. Please check your internet connection and try again.';
    }
  }

  void clearHistory() => _history.clear();
}
