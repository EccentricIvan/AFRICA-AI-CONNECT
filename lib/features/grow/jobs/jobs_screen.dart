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

const _jobTypes = ['Full-time', 'Part-time', 'Contract'];

String _colorKeyForType(String type) {
  switch (type) {
    case 'Part-time':
      return 'skills';
    case 'Contract':
      return 'mentorship';
    default:
      return 'health';
  }
}

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  void _openPostJobSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _PostJobSheet(),
    );
  }

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
                _JobsHero(onPostJob: () => _openPostJobSheet(context)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SectionHeader(
                        title: S.literal('Recent Opportunities'),
                        subtitle: S.literal('Jobs and gigs near you'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openPostJobSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(S.literal('Post a Job')),
                    ),
                  ],
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
  const _JobsHero({required this.onPostJob});
  final VoidCallback onPostJob;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      S.literal('Browse jobs and gigs posted by people in your community.'),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPostJob,
              icon: const Icon(Icons.add),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.jobsColor),
              label: Text(S.literal('Post a Job')),
            ),
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
          return Text(S.literal('No opportunities posted yet — be the first to post one!'));
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
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(j.location!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (j.description != null && j.description!.trim().isNotEmpty)
                    _JdSection(
                      title: S.literal('About this role'),
                      body: j.description!,
                      color: color,
                    ),
                  if (j.requirements != null && j.requirements!.trim().isNotEmpty)
                    _JdSection(
                      title: S.literal('Requirements'),
                      body: j.requirements!,
                      color: color,
                    ),
                  if (j.education != null && j.education!.trim().isNotEmpty)
                    _JdSection(
                      title: S.literal('Education'),
                      body: j.education!,
                      color: color,
                    ),
                  if (j.niceToHave != null && j.niceToHave!.trim().isNotEmpty)
                    _JdSection(
                      title: S.literal('Good to Have'),
                      body: j.niceToHave!,
                      color: color,
                    ),
                  const SizedBox(height: 4),
                  JobApplySection(jobId: j.id, color: color),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref, j.id),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                      label: Text(
                        S.literal('Delete this posting'),
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.literal('Delete this posting?')),
        content: Text(S.literal("It will be removed along with any applications to it. This can't be undone.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.literal('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.literal('Delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(jobsDaoProvider).deleteJob(jobId);
  }
}

class _JdSection extends StatelessWidget {
  const _JdSection({required this.title, required this.body, required this.color});
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
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

// ─────────────────────────── Post a Job form ───────────────────────

class _PostJobSheet extends ConsumerStatefulWidget {
  const _PostJobSheet();

  @override
  ConsumerState<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends ConsumerState<_PostJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _employerController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _educationController = TextEditingController();
  final _niceToHaveController = TextEditingController();
  String _type = _jobTypes.first;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _employerController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _educationController.dispose();
    _niceToHaveController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(jobsDaoProvider).postJob(
          title: _titleController.text.trim(),
          employer: _employerController.text.trim(),
          type: _type,
          colorKey: _colorKeyForType(_type),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          requirements: _requirementsController.text.trim().isEmpty
              ? null
              : _requirementsController.text.trim(),
          education: _educationController.text.trim().isEmpty
              ? null
              : _educationController.text.trim(),
          niceToHave: _niceToHaveController.text.trim().isEmpty
              ? null
              : _niceToHaveController.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    S.literal('Post a Job'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: S.literal('Job title')),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? S.literal('Enter a job title') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _employerController,
                    decoration: InputDecoration(hintText: S.literal('Company / organisation name')),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? S.literal('Enter a company name') : null,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _jobTypes.map((t) {
                      final selected = _type == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(hintText: S.literal('Location (optional)')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: S.literal('About this role — responsibilities, what the job involves'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _requirementsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: S.literal('Requirements — experience, skills needed'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _educationController,
                    decoration: InputDecoration(hintText: S.literal('Education required')),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _niceToHaveController,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: S.literal('Good to have (optional)')),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.jobsColor),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(S.literal('Post Job')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
