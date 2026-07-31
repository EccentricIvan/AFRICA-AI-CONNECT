import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:otic_connect/core/l10n/app_strings.dart';
import 'package:otic_connect/services/gemini_service.dart';

void main() {
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
