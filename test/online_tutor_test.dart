import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ai_connect_africa/ai_core/online/online_tutor.dart';

void main() {
  test('sends the question, chat and lesson, and returns the answer', () async {
    late Map<String, dynamic> sent;
    late http.Request request;
    final tutor = OnlineTutor(
      baseUrl: 'http://127.0.0.1:8787/',
      accessToken: 'abc',
      client: MockClient((req) async {
        request = req;
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'text': ' Glucose. ', 'model': 'm'}), 200);
      }),
    );
    final reply = await tutor.answer(
      'Why does it need light?',
      history: [(isUser: true, text: 'what is photosynthesis'), (isUser: false, text: 'It makes food.')],
      lesson: 'Topic: Photosynthesis',
    );
    expect(reply?.text, 'Glucose.');
    expect(reply?.suggestions, isEmpty);
    expect(request.url.toString(), 'http://127.0.0.1:8787/v1/tutor/answer');
    expect(request.headers['X-Otic-Tutor-Token'], 'abc');
    expect(sent['message'], 'Why does it need light?');
    expect(sent['lesson'], 'Topic: Photosynthesis');
    expect(sent['history'], [
      {'role': 'user', 'content': 'what is photosynthesis'},
      {'role': 'assistant', 'content': 'It makes food.'},
    ]);
  });

  test('a server without a key, or no server at all, gives null', () async {
    final noKey = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response('{"error":"not_configured"}', 503)),
    );
    expect(await noKey.answer('hi'), isNull);
    final down = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((_) async => throw const SocketException('refused')),
    );
    expect(await down.answer('hi'), isNull);
  });

  test('after a failure the server is left alone for a while', () async {
    var calls = 0;
    final tutor = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 503);
      }),
    );
    await tutor.answer('one');
    await tutor.answer('two');
    expect(calls, 1);
  });

  test('a hub content miss allows lookup without disabling the next hub request', () async {
    var calls = 0;
    final tutor = OnlineTutor(
      baseUrl: 'http://hub',
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('', 204)
            : http.Response('{"text":"Covered lesson","suggestions":[]}', 200);
      }),
    );
    expect(await tutor.answer('What is quantum entanglement?'), isNull);
    expect((await tutor.answer('What is convection?'))?.text, 'Covered lesson');
    expect(calls, 2);
  });

  test('only the last 12 messages are sent', () async {
    late Map<String, dynamic> sent;
    final tutor = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('{"text":"ok"}', 200);
      }),
    );
    await tutor.answer('q', history: [for (var i = 0; i < 20; i++) (isUser: i.isEven, text: 'm$i')]);
    expect((sent['history'] as List).length, 12);
    expect((sent['history'] as List).last['content'], 'm19');
  });

  test("a school hub's suggestions come back with its answer", () async {
    final hub = OnlineTutor(
      baseUrl: 'http://hub',
      client: MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'text': '**Heat Transfer — Part 1 of 3: Conduction**',
              'model': 'qwen3-4b',
              'suggestions': ['Next: Convection (Heat Transfer)', '', 'Quiz me on Conduction', 7],
            })),
            200,
          )),
    );
    final reply = await hub.answer('Teach me heat transfer');
    expect(reply?.suggestions, ['Next: Convection (Heat Transfer)', 'Quiz me on Conduction']);
  });

  test("a school hub's pictures and clips come back with their credits", () async {
    final asked = <Uri>[];
    final hub = OnlineTutor(
      baseUrl: 'http://hub:8787/',
      accessToken: 't0k',
      client: MockClient((req) async {
        asked.add(req.url);
        expect(req.headers['X-Otic-Tutor-Token'], 't0k');
        final clips = req.url.queryParameters['clips'] == 'true';
        return http.Response(
          jsonEncode({
            'items': [
              clips
                  ? {'kind': 'clip', 'url': 'http://hub:8787/v1/hub/media/physics/c.webm',
                     'poster': 'http://hub:8787/v1/hub/media/physics/c.jpg',
                     'caption': 'Convection in water', 'credit': 'B, CC0', 'seconds': 75}
                  : {'kind': 'image', 'url': 'http://hub:8787/v1/hub/media/physics/p.png',
                     'caption': 'Convection currents', 'credit': 'A, CC BY 4.0'},
            ],
          }),
          200,
        );
      }),
    );
    final pictures = await hub.pictures('convection');
    expect(pictures.single.caption, 'Convection currents');
    expect(pictures.single.credit, 'A, CC BY 4.0');
    final clips = await hub.clips('convection');
    expect(clips.single.poster, endsWith('c.jpg'));
    expect(clips.single.seconds, 75);
    expect(asked.first.toString(), 'http://hub:8787/v1/hub/pictures?q=convection&clips=false&max=4');
  });

  test('a tutor server without pictures, or none at all, gives none', () async {
    final claudeServer = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((_) async => http.Response('{"detail":"Not Found"}', 404)),
    );
    expect(await claudeServer.pictures('frog'), isEmpty);
    final down = OnlineTutor(
      baseUrl: 'http://x',
      client: MockClient((_) async => throw const SocketException('offline')),
    );
    expect(await down.clips('frog'), isEmpty);
  });
  test('streamed text is visible before completion, with split UTF-8 preserved', () async {
    final wire = StreamController<List<int>>();
    final tutor = OnlineTutor(baseUrl: 'http://hub', client: _WireClient((request) async {
      expect(request.url.path, '/v1/tutor/answer/stream');
      return http.StreamedResponse(wire.stream, 200, headers: {'content-type': 'text/event-stream'});
    }));
    final seen = <String>[];
    var completed = false;
    final pending = tutor.answer('q', onText: seen.add).then((value) {
      completed = true;
      return value;
    });
    await pumpEventQueue();
    final bytes = utf8.encode('data: ' + jsonEncode({'text': 'Caf\u00e9'}) + '\n\n');
    final split = bytes.indexOf(0xc3) + 1;
    wire.add(bytes.sublist(0, split));
    await pumpEventQueue();
    expect(seen, isEmpty);
    wire.add(bytes.sublist(split));
    await pumpEventQueue();
    expect(seen, ['Caf\u00e9']);
    expect(completed, false);
    wire.add(utf8.encode('data: ' + jsonEncode({'done': {
      'text': 'Final answer with source', 'suggestions': ['Next topic'],
    }}) + '\n\n'));
    await wire.close();
    final answer = await pending;
    expect(answer?.text, 'Final answer with source');
    expect(answer?.suggestions, ['Next topic']);
  });

  test('older servers use the JSON endpoint when streaming is absent', () async {
    final paths = <String>[];
    final tutor = OnlineTutor(baseUrl: 'http://old', client: MockClient((request) async {
      paths.add(request.url.path);
      return request.url.path.endsWith('/stream')
          ? http.Response('', 404)
          : http.Response('{"text":"Legacy answer"}', 200);
    }));
    expect((await tutor.answer('q', onText: (_) {}))?.text, 'Legacy answer');
    expect(paths, ['/v1/tutor/answer/stream', '/v1/tutor/answer']);
  });

  test('interrupted streams clear partial text and allow normal fallback', () async {
    final seen = <String>[];
    final tutor = OnlineTutor(baseUrl: 'http://hub', client: MockClient((_) async =>
      http.Response('data: {"text":"Partial"}\n\ndata: {"error":"offline"}\n\n', 200)));
    expect(await tutor.answer('q', onText: seen.add), isNull);
    expect(seen, ['Partial', '']);
  });

  test('stream content miss does not block the next covered answer', () async {
    var calls = 0;
    final tutor = OnlineTutor(baseUrl: 'http://hub', client: MockClient((_) async {
      calls++;
      return calls == 1 ? http.Response('', 204) :
        http.Response('data: {"done":{"text":"Covered answer"}}\n\n', 200);
    }));
    expect(await tutor.answer('unknown', onText: (_) {}), isNull);
    expect((await tutor.answer('covered', onText: (_) {}))?.text, 'Covered answer');
    expect(calls, 2);
  });

}


class _WireClient extends http.BaseClient {
  _WireClient(this.handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}
