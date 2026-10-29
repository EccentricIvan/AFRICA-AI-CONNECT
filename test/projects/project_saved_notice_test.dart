import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_connect_africa/features/projects/widgets/project_saved_notice.dart';

Widget harness({bool accessible = false, VoidCallback? onOpen}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(accessibleNavigation: accessible),
    child: child!,
  ),
  home: Scaffold(body: Builder(builder: (context) => Column(children: [
    for (final name in ['Website A', 'Website B'])
      TextButton(
        onPressed: () => showProjectSavedNotice(context, name: name, onOpen: onOpen ?? () {}),
        child: Text('Save $name'),
      ),
  ]))),
);

void main() {
  for (final accessible in [false, true]) {
    testWidgets('save notice expires with Open action, accessibility=$accessible', (tester) async {
      await tester.pumpWidget(harness(accessible: accessible));
      await tester.tap(find.text('Save Website A'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('save notice can be closed without opening the project', (tester) async {
    var opens = 0;
    await tester.pumpWidget(harness(onOpen: () => opens++));
    await tester.tap(find.text('Save Website A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(opens, 0);
  });

  testWidgets('repeated saves replace the notice instead of queuing', (tester) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Save Website A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Website B'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved “Website A”'), findsNothing);
    expect(find.textContaining('Saved “Website B”'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Open still opens the saved project and dismisses the notice', (tester) async {
    var opens = 0;
    await tester.pumpWidget(harness(onOpen: () => opens++));
    await tester.tap(find.text('Save Website A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect(find.byType(SnackBar), findsNothing);
  });
}