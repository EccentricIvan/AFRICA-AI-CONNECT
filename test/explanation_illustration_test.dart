import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_connect_africa/curriculum/online_topic_lookup.dart';
import 'package:ai_connect_africa/curriculum/topic_explanations.dart';
import 'package:ai_connect_africa/shared/widgets/explanation_illustration.dart';
import 'package:ai_connect_africa/shared/widgets/curriculum_diagram.dart';

class DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}

const diagram = 'assets/curriculum/diagrams/biology/photosynthesis.svg';
const illustration = ExplanationPicture(
  path: diagram,
  subject: 'photosynthesis',
  guidance: 'Follow the arrows from sunlight to the leaf.',
  credit: 'Curriculum diagram',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'photosynthesis automatically uses the real labelled diagram offline',
    () async {
      final service = TopicExplanationService(
        bundle: DiskBundle(),
        updatesDir: () async => null,
      );
      var externalCalls = 0;
      final visual = await findExplanationPicture(
        'what is photosynthesis',
        local: service.localPicture,
        internet: (_) async {
          externalCalls++;
          return [];
        },
      );
      expect(visual?.path, diagram);
      expect(visual?.guidance, contains('water'));
      expect(visual?.guidance, contains('carbon dioxide'));
      expect(visual?.guidance, contains('Oxygen'));
      expect(externalCalls, 0);
    },
  );
  test('hub picture wins and retains its credit', () async {
    var internetCalls = 0;
    final visual = await findExplanationPicture(
      'what is convection',
      local: (_) async => null,
      hub: (_) async => [
        const WebPicture(
          url: 'http://hub/convection.png',
          caption: 'Warm water rises',
          credit: 'School pack, CC0',
        ),
      ],
      internet: (_) async {
        internetCalls++;
        return [];
      },
    );
    expect(visual?.path, 'http://hub/convection.png');
    expect(visual?.credit, 'School pack, CC0');
    expect(internetCalls, 0);
  });
  test(
    'internet picture fills a missing hub visual and retains caption/credit',
    () async {
      final visual = await findExplanationPicture(
        'Explain volcanoes',
        local: (_) async => null,
        hub: (_) async => [],
        internet: (subject) async {
          expect(subject, 'volcanoes');
          return [
            const WebPicture(
              url: 'https://example/volcano.png',
              caption: 'Lava flows from the vent',
              credit: 'Artist, CC BY 4.0',
            ),
          ];
        },
      );
      expect(visual?.guidance, 'Lava flows from the vent');
      expect(visual?.credit, contains('CC BY'));
    },
  );
  test(
    'missing or disconnected pictures leave the text answer alone',
    () async {
      expect(
        await findExplanationPicture(
          'Explain gravity',
          local: (_) async => null,
          internet: (_) async => throw const SocketException('offline'),
        ),
        isNull,
      );
    },
  );
  test(
    'greetings and safety messages do not trigger picture searches',
    () async {
      var calls = 0;
      for (final question in ['hello', 'i feel like killing myself']) {
        expect(
          await findExplanationPicture(
            question,
            local: (_) async {
              calls++;
              return null;
            },
          ),
          isNull,
        );
      }
      expect(calls, 0);
    },
  );
  testWidgets(
    'text stays visible while the visual loads, then a labelled SVG appears',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<ExplanationPicture?>();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Plants use sunlight to make food.'),
                    ExplanationIllustration(
                      question: 'what is photosynthesis',
                      resolve: (_) => pending.future,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Plants use sunlight to make food.'), findsOneWidget);
      expect(find.byType(CurriculumDiagram), findsNothing);
      pending.complete(illustration);
      await tester.pumpAndSettle();
      expect(find.text('Picture explanation'), findsOneWidget);
      expect(find.byType(CurriculumDiagram), findsOneWidget);
      expect(find.text(illustration.guidance), findsOneWidget);
      expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Enlarge picture'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    },
  );
  testWidgets('a missing visual has no loading spinner or empty picture card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ExplanationIllustration(
            question: 'Explain gravity',
            resolve: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Picture explanation'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
