import 'package:flutter/services.dart';
import 'package:ai_connect_africa/core/theme/app_theme.dart';
import 'package:ai_connect_africa/features/learners/learner_picker_screen.dart';
import 'package:ai_connect_africa/features/learners/learner_pin.dart';
import 'package:ai_connect_africa/features/teacher/class_providers.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:ai_connect_africa/core/policy/policy.dart';
import 'package:ai_connect_africa/db/otic_database.dart';
import 'package:ai_connect_africa/db/providers/db_provider.dart';
import 'package:ai_connect_africa/features/access/school_access_screen.dart';
import 'package:ai_connect_africa/features/admin/admin_service.dart';
import 'package:ai_connect_africa/features/teacher/teacher_pin.dart';
import 'package:ai_connect_africa/features/teacher/teacher_profiles.dart';
import 'package:ai_connect_africa/features/teachers/teachers_screen.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OticDatabase db;
  late ProviderContainer container;
  late AdminSession admin;
  late TeacherProfile teacher;
  var closed = false;

  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(
        File(
          'assets/fonts/Inter-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    await font.load();
  });
  setUp(() async {
    closed = false;
    SharedPreferences.setMockInitialValues({});
    pinHashInIsolate = false;
    pinKdfRounds = 2;
    db = OticDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    final service = container.read(adminServiceProvider);
    admin = (await service.setUp(name: 'Head teacher', pin: '2468'))!;
    await service.addTeacher(admin, name: 'Amina', pin: '1234');
    teacher =
        (await container.read(teacherProfileServiceProvider).all()).single;
    // Existing installations may still store the old shared lock.
    await TeacherPin().set('9999');
  });
  tearDown(() async {
    if (!closed) {
      container.dispose();
      await db.close();
    }
    pinHashInIsolate = true;
    pinKdfRounds = 20000;
  });

  test('school permissions remain active without the shared PIN', () async {
    await TeacherPin().clear();
    final policy = container.read(policyProvider);
    expect(await policy.readableSubjects(const GuestActor()), isEmpty);
  });

  test(
    'the notes actor follows the authenticated role, never the legacy unlock',
    () async {
      container.read(adminSessionProvider.notifier).state = admin;
      expect(
        await container.read(notesActorProvider.future),
        isA<AdminActor>(),
      );
      container.read(adminSessionProvider.notifier).state = null;
      container.read(activeTeacherProvider.notifier).state = teacher;
      expect(
        await container.read(notesActorProvider.future),
        isA<TeacherActor>(),
      );
      container.read(activeTeacherProvider.notifier).state = null;
      container.read(teacherUnlockedProvider.notifier).state = true;
      expect(
        await container.read(notesActorProvider.future),
        isNot(isA<TeacherActor>()),
      );
    },
  );

  testWidgets(
    'one personal PIN opens the requested tool despite an old shared PIN',
    (tester) async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          dbProvider.overrideWithValue(db),
          teacherProfilesProvider.overrideWith(
            (ref) => Stream.value([teacher]),
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: '/teachers?to=%2Fteacher%2Fmaterials',
        routes: [
          GoRoute(
            path: '/teachers',
            builder: (_, __) => const TeachersScreen(),
          ),
          GoRoute(
            path: '/teacher/materials',
            builder: (_, __) => const Text('Materials workspace'),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const Text('Admin workspace'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('access-capture'),
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              builder: (_, child) =>
                  ColoredBox(color: Colors.white, child: child!),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Teachers PIN'), findsNothing);
      expect(find.text('School cloud'), findsNothing);
      expect(find.text('Amina'), findsOneWidget);
      await tester.tap(find.text('Amina'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1111');
      await tester.tap(find.text('OK'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(container.read(activeTeacherProvider), isNull);
      expect(find.text('Materials workspace'), findsNothing);
      await tester.tap(find.text('Amina'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('OK'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Materials workspace'), findsOneWidget);
      expect(container.read(activeTeacherProvider)?.id, teacher.id);
      container.read(activeTeacherProvider.notifier).state = null;
      container.read(adminSessionProvider.notifier).state = null;
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await db.close();
        closed = true;
      });
    },
  );

  testWidgets(
    'student handover clears every staff session before choosing a learner',
    (tester) async {
      container.read(adminSessionProvider.notifier).state = admin;
      container.read(activeTeacherProvider.notifier).state = teacher;
      container.read(teacherUnlockedProvider.notifier).state = true;
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/access',
        routes: [
          GoRoute(
            path: '/access',
            builder: (_, __) => const SchoolAccessScreen(),
          ),
          GoRoute(
            path: '/learners',
            builder: (_, __) => const Text('Choose student'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('access-capture'),
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              theme: AppTheme.light,
              builder: (_, child) =>
                  ColoredBox(color: Colors.white, child: child!),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('access-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/school-access-preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Student'));
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('Choose student'), findsOneWidget);
      expect(container.read(activeTeacherProvider), isNull);
      expect(container.read(adminSessionProvider), isNull);
      expect(container.read(teacherUnlockedProvider), isFalse);
      container.read(activeTeacherProvider.notifier).state = null;
      container.read(adminSessionProvider.notifier).state = null;
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await db.close();
        closed = true;
      });
    },
  );
  testWidgets('returning to the current student still asks for their PIN', (
    tester,
  ) async {
    final student = await tester.runAsync(() async {
      final id = await db.studentDao.createStudent(
        StudentsCompanion.insert(name: 'Learner'),
      );
      await container.read(learnerPinServiceProvider).set(id, '4567');
      return (await db.studentDao.getStudentById(id))!;
    });
    container.dispose();
    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        activeStudentProvider.overrideWith((ref) async => student),
        allLearnersProvider.overrideWith((ref) => Stream.value([student!])),
        classGroupsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    final router = GoRouter(
      initialLocation: '/learners',
      routes: [
        GoRoute(
          path: '/learners',
          builder: (_, __) => const LearnerPickerScreen(),
        ),
        GoRoute(path: '/', builder: (_, __) => const Text('Student home')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current'), findsOneWidget);
    await tester.tap(find.text('Learner'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Student home'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await db.close();
      closed = true;
    });
  });
}
