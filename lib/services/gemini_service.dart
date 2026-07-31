import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/l10n/app_strings.dart';
import 'api_config.dart';

class ChatServiceResult {
  const ChatServiceResult.success(this.text)
      : errorCode = null,
        retryable = false;

  const ChatServiceResult.failure(this.errorCode, {required this.retryable})
      : text = null;

  final String? text;
  final String? errorCode;
  final bool retryable;
  bool get isSuccess => text != null;
}

/// Africa AI Connect backend client. Provider secrets stay on FastAPI.
class GeminiService {
  GeminiService({http.Client? client, String? backendBaseUrl})
      : _client = client ?? http.Client(),
        _backendBaseUrl = backendBaseUrl ?? ApiConfig.backendBaseUrl;

  final http.Client _client;
  final String _backendBaseUrl;
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

  Future<ChatServiceResult> sendMessage(
    String message,
    AppLocale selectedLocale,
  ) async {
    if (_backendBaseUrl.isEmpty) {
      return const ChatServiceResult.failure(
        'CHAT_PROVIDER_UNAVAILABLE',
        retryable: true,
      );
    }

    final context = _history
        .map((item) => {'role': item['role'], 'content': item['content']})
        .toList(growable: false);

    try {
      final response = await _client
          .post(
            Uri.parse('${_backendBaseUrl.replaceAll(RegExp(r'/+$'), '')}/chat'),
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
          _history
            ..add({'role': 'user', 'content': message})
            ..add({'role': 'assistant', 'content': text.trim()});
          return ChatServiceResult.success(text.trim());
        }
      }

      if (data is Map<String, dynamic> && data['error'] is Map) {
        final error = Map<String, dynamic>.from(data['error'] as Map);
        final code = error['code'];
        final retryable = error['retryable'];
        if (code is String) {
          return ChatServiceResult.failure(
            code,
            retryable: retryable is bool ? retryable : false,
          );
        }
      }
      return const ChatServiceResult.failure(
        'CHAT_PROVIDER_UNAVAILABLE',
        retryable: true,
      );
    } on SocketException catch (_) {
      return const ChatServiceResult.failure(
        'CHAT_NETWORK_OFFLINE',
        retryable: true,
      );
    } on TimeoutException catch (_) {
      return const ChatServiceResult.failure(
        'CHAT_PROVIDER_UNAVAILABLE',
        retryable: true,
      );
    } on FormatException catch (_) {
      return const ChatServiceResult.failure(
        'CHAT_PROVIDER_UNAVAILABLE',
        retryable: true,
      );
    } catch (_) {
      return const ChatServiceResult.failure(
        'CHAT_NETWORK_OFFLINE',
        retryable: true,
      );
    }
  }

  void clearHistory() => _history.clear();

  int get historyLength => _history.length;
}
