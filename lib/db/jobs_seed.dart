import 'daos/jobs_dao.dart';

/// One-time seed of curated job board postings, mirroring the demo content
/// that used to be hardcoded directly in jobs_screen.dart. Safe to call
/// repeatedly — no-ops once any job exists — same idempotent-on-launch
/// shape as seedChatContentFromAsset.
Future<void> seedJobsIfEmpty(JobsDao dao) async {
  if (await dao.hasAnyJobs()) return;
  await dao.seedJob(
    title: 'Community Health Worker',
    employer: 'NGO Partner · Kampala',
    type: 'Full-time',
    colorKey: 'health',
    location: 'Kampala',
    description:
        'Support household health visits, maternal health education, and '
        'referrals in your community. Training provided.',
  );
  await dao.seedJob(
    title: 'Digital Marketing Assistant',
    employer: 'Tech Hub · Remote',
    type: 'Part-time',
    colorKey: 'skills',
    location: 'Remote',
    description:
        'Help small businesses grow their social media presence. Basic '
        'computer literacy required; social media experience a plus.',
  );
  await dao.seedJob(
    title: 'Agricultural Extension Officer',
    employer: 'District Gov · Mbale',
    type: 'Contract',
    colorKey: 'health',
    location: 'Mbale',
    description:
        'Advise local farmers on modern techniques and connect them with '
        'agribusiness resources. Agriculture background preferred.',
  );
  await dao.seedJob(
    title: 'Tailoring Trainer',
    employer: "Women's Centre · Jinja",
    type: 'Part-time',
    colorKey: 'mentorship',
    location: 'Jinja',
    description:
        'Teach tailoring and garment-making skills to women in a '
        'community training programme. Sewing experience required.',
  );
}
