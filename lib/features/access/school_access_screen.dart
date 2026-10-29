import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/admin_service.dart';
import '../teacher/teacher_pin.dart';
import '../teacher/teacher_profiles.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/studio_page.dart';

void returnToStudent(BuildContext context, WidgetRef ref) {
  ref.read(activeTeacherProvider.notifier).state = null;
  ref.read(adminSessionProvider.notifier).state = null;
  ref.read(teacherUnlockedProvider.notifier).state = false;
  context.go('/learners');
}

class SchoolAccessScreen extends ConsumerWidget {
  const SchoolAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(activeTeacherProvider);
    final admin = ref.watch(adminSessionProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const StudioAppBar(
        title: 'School access',
        subtitle: 'Choose your workspace',
        icon: Icons.school_rounded,
      ),
      body: MaxWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'One school. Three clear roles.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'The Admin sets up the school and assigns teachers. '
              'Teachers manage their classes. Students choose their name and learn.',
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.admin_panel_settings_rounded),
                title: const Text('Admin'),
                subtitle: Text(
                  admin == null
                      ? 'Set up the school, add teachers and assign classes and subjects. Sign in with your Admin PIN.'
                      : 'Signed in as ${admin.name}. Continue managing the school.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/admin'),
              ),
            ),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.school_outlined),
                title: const Text('Teacher'),
                subtitle: Text(
                  teacher == null
                      ? 'Choose your name and enter your own PIN. Open your classes, materials and assignments.'
                      : 'Signed in as ${teacher.name}. Continue teaching.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/teachers'),
              ),
            ),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Student'),
                subtitle: const Text(
                  'Choose your name and start learning. Staff access closes when you return to a student.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => returnToStudent(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
