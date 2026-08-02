import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';
import 'package:otic_connect/services/gemini_service.dart';

void main() {
  test('all supported local languages are sent with Sunbird codes', () async {
    final expectedCodes = {
      AppLocale.nyn: 'nyn',
      AppLocale.teo: 'teo',
      AppLocale.nyo: 'nyo',
      AppLocale.ach: 'ach',
    };

    for (final entry in expectedCodes.entries) {
      late Map<String, dynamic> payload;
      final service = GeminiService(
        backendBaseUrl: 'https://example.test',
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'response': 'Local answer', 'provider': 'sunbird+groq+sunbird'}),
            200,
          );
        }),
      );

      await service.sendMessage('Local question', entry.key);
      expect(payload['language'], entry.value);
    }
  });

  test('structured authentication error contains no provider details', () async {
    final service = GeminiService(
      backendBaseUrl: 'https://example.test',
      client: MockClient((request) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'CHAT_PROVIDER_AUTH_FAILED',
                'retryable': false,
              },
            }),
            502,
          )),
    );

    final result = await service.sendMessage('Hi there.', AppLocale.en);
    expect(result.errorCode, 'CHAT_PROVIDER_AUTH_FAILED');
    expect(result.retryable, isFalse);
    expect(result.toString(), isNot(contains('api.groq.com')));
    expect(service.historyLength, 0);
  });

  test('failed message is not duplicated in conversation history', () async {
    var attempts = 0;
    final service = GeminiService(
      backendBaseUrl: 'https://example.test',
      client: MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'CHAT_PROVIDER_UNAVAILABLE',
                'retryable': true,
              },
            }),
            503,
          );
        }
        return http.Response(
          jsonEncode({'response': 'Ndi bulungi.', 'provider': 'sunbird'}),
          200,
        );
      }),
    );

    final failed = await service.sendMessage('Oli otya?', AppLocale.lg);
    expect(failed.retryable, isTrue);
    expect(service.historyLength, 0);

    final retried = await service.sendMessage('Oli otya?', AppLocale.lg);
    expect(retried.text, 'Ndi bulungi.');
    expect(service.historyLength, 2);

    service.clearHistory();
    expect(service.historyLength, 0);
  });
}
