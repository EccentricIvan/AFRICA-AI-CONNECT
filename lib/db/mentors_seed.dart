import 'daos/mentors_dao.dart';

/// One-time seed of the curated mentor directory, mirroring the demo
/// content that used to be hardcoded directly in mentorship_screen.dart.
Future<void> seedMentorsIfEmpty(MentorsDao dao) async {
  if (await dao.hasAnyMentors()) return;
  await dao.seedMentor(
    name: 'Amina B.',
    expertise: 'Agriculture & Agribusiness',
    location: 'Kampala',
    yearsExp: 12,
    colorKey: 'health',
  );
  await dao.seedMentor(
    name: 'Florence N.',
    expertise: 'Financial Management',
    location: 'Jinja',
    yearsExp: 8,
    colorKey: 'finance',
  );
  await dao.seedMentor(
    name: 'Esther K.',
    expertise: 'Digital Marketing',
    location: 'Mbale',
    yearsExp: 5,
    colorKey: 'chat',
  );
  await dao.seedMentor(
    name: 'Harriet O.',
    expertise: 'Entrepreneurship',
    location: 'Kampala',
    yearsExp: 15,
    colorKey: 'earn',
  );
}
