import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class GeminiService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt =
      '''You are Africa AI Connect AI Assistant — a warm, supportive, and knowledgeable companion for women in Sub-Saharan Africa.

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

  Future<String> sendMessage(String message) async {
    if (ApiConfig.groqKey.isEmpty) {
      return 'API key not configured. Please contact support.';
    }

    _history.add({'role': 'user', 'content': message});

    final messages = [
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
}
