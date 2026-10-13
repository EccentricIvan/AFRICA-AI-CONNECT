import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/otic_database.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/studio_page.dart';
import 'class_providers.dart';
import 'class_teacher_service.dart';
import 'teacher_profiles.dart';

/// The classes/streams the signed-in teacher registers learners into, as a
/// Class Teacher. Empty when they aren't one.
final myClassTeacherClassesProvider =
    FutureProvider.autoDispose<List<ClassGroup>>((ref) {
      final me = ref.watch(activeTeacherIdProvider);
      return ref.watch(classTeacherServiceProvider).classesOf(me);
    });

final _registeredProvider = StreamProvider.autoDispose
    .family<List<RegisteredLearner>, int>(
      (ref, teacherId) =>
          ref.watch(classTeacherServiceProvider).watchRegistered(teacherId),
    );

/// Teacher → Register learners: a Class Teacher adds new learners to the
/// classes/streams the Admin gave them. They reach the Admin's device at the
/// next Admin sync. Names and classes only — no grades or progress here.
class RegisterLearnersScreen extends ConsumerStatefulWidget {
  const RegisterLearnersScreen({super.key});

  @override
  ConsumerState<RegisterLearnersScreen> createState() =>
      _RegisterLearnersScreenState();
}

class _RegisterLearnersScreenState
    extends ConsumerState<RegisterLearnersScreen> {
  final _name = TextEditingController();
  String? _classUuid;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _register(List<ClassGroup> classes) async {
    final group = classes.where((c) => c.groupUuid == _classUuid).firstOrNull;
    if (group == null) {
      setState(() => _error = 'Pick a class or stream.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _name.text;
    final error = await ref
        .read(classTeacherServiceProvider)
        .register(
          teacherId: ref.read(activeTeacherIdProvider),
          name: name,
          group: group,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) {
      _name.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${name.trim()} registered')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(activeTeacherIdProvider);
    final classes =
        ref.watch(myClassTeacherClassesProvider).valueOrNull ??
        const <ClassGroup>[];
    final byUuid = {for (final c in classes) c.groupUuid: c};
    if (_classUuid == null && classes.length == 1) {
      _classUuid = classes.single.groupUuid;
    }
    final registered = me == null
        ? const <RegisteredLearner>[]
        : ref.watch(_registeredProvider(me)).valueOrNull ??
              const <RegisteredLearner>[];
    final waiting = registered.where((r) => !r.withAdmin).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const StudioAppBar(
        title: 'Register learners',
        subtitle: 'Class teacher',
        icon: Icons.how_to_reg_rounded,
        showBack: true,
      ),
      body: MaxWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (classes.isEmpty)
              const StudioCard(
                child: Text('The Admin hasn’t given you a class or stream.'),
              )
            else
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _classUuid,
                      decoration: const InputDecoration(
                        labelText: 'Class / stream',
                      ),
                      items: [
                        for (final c in classes)
                          if (c.groupUuid case final uuid?)
                            DropdownMenuItem(
                              value: uuid,
                              child: Text(classLabel(c)),
                            ),
                      ],
                      onChanged: (v) => setState(() => _classUuid = v),
                    ),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 80,
                      onSubmitted: (_) => _register(classes),
                      decoration: InputDecoration(
                        labelText: 'Learner’s name',
                        errorText: _error,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _register(classes),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Register'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (registered.isNotEmpty)
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered by you',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (waiting > 0)
                      Text(
                        '$waiting waiting for Admin sync',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    for (final r in registered)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          r.withAdmin
                              ? Icons.check_circle_outline_rounded
                              : Icons.schedule_rounded,
                        ),
                        title: Text(r.name),
                        subtitle: Text(
                          [
                            if (byUuid[r.classGroupUuid] case final c?)
                              classLabel(c),
                            r.withAdmin ? 'With the Admin' : 'Waiting for Admin sync',
                          ].join(' · '),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
