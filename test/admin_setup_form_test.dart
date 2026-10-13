import 'package:ai_connect_africa/db/otic_database.dart';
import 'package:ai_connect_africa/db/providers/db_provider.dart';
import 'package:ai_connect_africa/features/admin/admin_screen.dart';
import 'package:ai_connect_africa/features/admin/admin_service.dart';
import 'package:ai_connect_africa/features/admin/admin_sync_widgets.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OticDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = OticDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
  });
  tearDown(() => db.close());

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          adminSetUpProvider.overrideWith((ref) async => false),
          adminRecordsStateProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: AdminScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(field('Name'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Set up'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  testWidgets('an empty first PIN asks for a PIN, not "did not match"',
      (tester) async {
    await open(tester);
    await tester.enterText(field('Name'), 'Head');
    await tester.enterText(field('PIN again'), '2468');
    await submit(tester);
    expect(find.text('Enter a PIN.'), findsOneWidget);
    expect(find.text('The two PINs did not match.'), findsNothing);
  });

  testWidgets('different PINs say so; matching PINs create the Admin',
      (tester) async {
    await open(tester);
    await tester.enterText(field('Name'), 'Head');
    await tester.enterText(field('PIN (4–8 digits)'), '2468');
    await tester.enterText(field('PIN again'), '2469');
    await submit(tester);
    expect(find.text('The two PINs did not match.'), findsOneWidget);

    await tester.enterText(field('PIN again'), '2468');
    await tester.pump();
    expect(
      find.text('The two PINs did not match.'),
      findsNothing,
      reason: 'cleared while typing',
    );
    await submit(tester);
    // The PIN is stretched with PBKDF2, so saving takes a moment.
    final admin = await tester.runAsync(() async {
      for (var i = 0; i < 300; i++) {
        final rows = await db.select(db.adminIdentity).get();
        if (rows.isNotEmpty) return rows;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return <AdminIdentityRow>[];
    });
    expect(admin!.single.name, 'Head');
    await tester.pumpWidget(const SizedBox());
  });
}
