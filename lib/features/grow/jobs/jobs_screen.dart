import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/section_header.dart';
import 'job_detail_screen.dart';
import 'cv_editor_screen.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.literal('Job Board')),
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
                const _JobsHero(),
                const SizedBox(height: 24),
                SectionHeader(
                  title: S.literal('Recent Opportunities'),
                  subtitle: S.literal('Jobs and gigs near you'),
                ),
                const SizedBox(height: 12),
                const _JobListings(),
                const SizedBox(height: 24),
                SectionHeader(
                  title: S.literal('Build Your CV'),
                  subtitle: S.literal('Create a professional profile'),
                ),
                const SizedBox(height: 12),
                const _CvBuilderCard(),
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
  const _JobsHero();

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
        border: Border.all(
            color: AppColors.jobsColor.withValues(alpha: 0.15)),
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
                  S.literal('Browse jobs, freelance gigs, and training programmes from verified employers.'),
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
            child: const Icon(Icons.work,
                color: AppColors.jobsColor, size: 28),
          ),
        ],
      ),
    );
  }
}

class _JobListings extends ConsumerWidget {
  const _JobListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);

    return jobsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text(S.literal('Could not load jobs. Try again later.')),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Text(S.literal('No opportunities posted yet.'));
        }
        return Column(
          children: jobs.map((j) {
            final color = colorForJobKey(j.colorKey);
            return Card(
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: j.id)),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work, color: color, size: 22),
                ),
                title: Text(j.title,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(j.employer),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    j.type,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CvBuilderCard extends StatelessWidget {
  const _CvBuilderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.skillsColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.skillsColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description,
                  color: AppColors.skillsColor, size: 24),
              const SizedBox(width: 10),
              Text(S.literal('CV Builder'),
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.literal('Write down your experience, skills, and education so employers can see who you are.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CvEditorScreen()),
            ),
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
