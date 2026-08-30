import 'daos/courses_dao.dart';

/// One-time seed of curated skills-training programmes, mirroring the demo
/// content that used to be hardcoded directly in skills_screen.dart.
Future<void> seedCoursesIfEmpty(CoursesDao dao) async {
  if (await dao.hasAnyCourses()) return;
  await dao.seedCourse(
    title: 'Digital Literacy',
    subtitle: 'Phone, internet, and computer basics',
    iconKey: 'computer',
    colorKey: 'skills',
    lessonCount: 6,
  );
  await dao.seedCourse(
    title: 'Business Management',
    subtitle: 'Planning, accounting, and operations',
    iconKey: 'business_center',
    colorKey: 'earn',
    lessonCount: 5,
  );
  await dao.seedCourse(
    title: 'Value Addition',
    subtitle: 'Processing, packaging, and branding products',
    iconKey: 'inventory',
    colorKey: 'marketplace',
    lessonCount: 4,
  );
  await dao.seedCourse(
    title: 'Communication Skills',
    subtitle: 'Negotiation, presentation, and networking',
    iconKey: 'record_voice_over',
    colorKey: 'community',
    lessonCount: 5,
  );
}
