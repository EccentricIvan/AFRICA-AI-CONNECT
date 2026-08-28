import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/section_header.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.literal('Job Board')),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JobsHero(),
                const SizedBox(height: 24),
                SectionHeader(
                  title: S.literal('Recent Opportunities'),
                  subtitle: S.literal('Jobs and gigs near you'),
                ),
                const SizedBox(height: 12),
                _JobListings(),
                const SizedBox(height: 24),
                SectionHeader(
                  title: S.literal('Build Your CV'),
                  subtitle: S.literal('Create a professional profile'),
                ),
                const SizedBox(height: 12),
                _CvBuilderCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.jobsColor.withValues(alpha: 0.12),
            AppColors.growColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.jobsColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.literal('Find your next opportunity'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  S.literal(
                    'Browse jobs, freelance gigs, and training programmes from verified employers.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.jobsColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.work, color: AppColors.jobsColor, size: 28),
          ),
        ],
      ),
    );
  }
}

class _JobListings extends StatelessWidget {
  static const _jobs = [
    _Job(
      'Community Health Worker',
      'NGO Partner · Kampala',
      'Full-time',
      AppColors.healthColor,
    ),
    _Job(
      'Digital Marketing Assistant',
      'Tech Hub · Remote',
      'Part-time',
      AppColors.skillsColor,
    ),
    _Job(
      'Agricultural Extension Officer',
      'District Gov · Mbale',
      'Contract',
      AppColors.healthColor,
    ),
    _Job(
      'Tailoring Trainer',
      'Women\'s Centre · Jinja',
      'Part-time',
      AppColors.mentorshipColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          _jobs.map((j) {
            return Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: j.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work, color: j.color, size: 22),
                ),
                title: Text(
                  S.literal(j.title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(S.literal(j.employer)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: j.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    S.literal(j.type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: j.color,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _Job {
  const _Job(this.title, this.employer, this.type, this.color);
  final String title;
  final String employer;
  final String type;
  final Color color;
}

class _CvBuilderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.skillsColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.skillsColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: AppColors.skillsColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                S.literal('CV Builder'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.literal(
              'Create a professional CV that highlights your skills and experience. AI-assisted — just answer a few questions.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skillsColor,
            ),
            child: Text(S.literal('Create CV')),
          ),
        ],
      ),
    );
  }
}
