import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/section_header.dart';
import 'cv_editor_screen.dart';

Color colorForJobKey(String key) {
  switch (key) {
    case 'health':
      return AppColors.healthColor;
    case 'skills':
      return AppColors.skillsColor;
    case 'mentorship':
      return AppColors.mentorshipColor;
    default:
      return AppColors.jobsColor;
  }
}

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
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
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
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (j.location != null) ...[
                    Text(
                      j.location!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (j.description != null) ...[
                    Text(j.description!, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                  JobApplySection(jobId: j.id, color: color),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Shown inside each job's inline dropdown — switches to a confirmation
/// once the local user has already applied.
class JobApplySection extends ConsumerStatefulWidget {
  const JobApplySection({super.key, required this.jobId, required this.color});
  final int jobId;
  final Color color;

  @override
  ConsumerState<JobApplySection> createState() => _JobApplySectionState();
}

class _JobApplySectionState extends ConsumerState<JobApplySection> {
  final _coverNoteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _coverNoteController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _submitting = true);
    final user = await ref.read(currentUserProvider.future);
    await ref.read(jobsDaoProvider).apply(
          jobId: widget.jobId,
          applicantName: user?.name ?? S.literal('Applicant'),
          coverNote: _coverNoteController.text.trim().isEmpty
              ? null
              : _coverNoteController.text.trim(),
        );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final applicationAsync = ref.watch(myJobApplicationProvider(widget.jobId));

    return applicationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (application) {
        if (application != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(S.literal('Applied — the employer will contact you.'))),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _coverNoteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: S.literal('Add a short note (optional)'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _apply,
                style: ElevatedButton.styleFrom(backgroundColor: widget.color),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(S.literal('Apply')),
              ),
            ),
          ],
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
