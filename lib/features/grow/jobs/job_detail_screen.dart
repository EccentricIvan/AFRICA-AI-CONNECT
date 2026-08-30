import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';

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

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: Text(S.literal('Job Details'))),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load this job.'))),
        data: (job) {
          if (job == null) {
            return Center(child: Text(S.literal('This posting is no longer available.')));
          }
          final color = colorForJobKey(job.colorKey);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.work, color: color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
                              Text(job.employer, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(job.type)),
                        if (job.location != null) Chip(label: Text(job.location!)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (job.description != null) ...[
                      Text(S.literal('About this role'), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(job.description!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                    ],
                    _ApplySection(jobId: job.id, color: color),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplySection extends ConsumerStatefulWidget {
  const _ApplySection({required this.jobId, required this.color});
  final int jobId;
  final Color color;

  @override
  ConsumerState<_ApplySection> createState() => _ApplySectionState();
}

class _ApplySectionState extends ConsumerState<_ApplySection> {
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
            Text(S.literal('Apply for this role'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
