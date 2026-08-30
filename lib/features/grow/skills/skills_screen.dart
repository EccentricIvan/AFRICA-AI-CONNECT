import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../db/providers/database_provider.dart';
import 'course_detail_screen.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.literal('Skills & Training'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.skillsColor.withValues(alpha: 0.12),
                        AppColors.growColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.skillsColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.literal('Build future-ready skills'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall),
                            const SizedBox(height: 6),
                            Text(
                              S.literal('Practical training programmes to boost your career and business.'),
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
                          color: AppColors.skillsColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: AppColors.skillsColor, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: S.literal('Training Programmes'),
                  subtitle: S.literal('Upskill with structured courses'),
                ),
                const SizedBox(height: 12),
                coursesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Text(S.literal('Could not load courses. Try again later.')),
                  data: (courses) => Column(
                    children: [
                      for (final course in courses) ...[
                        _CourseCard(courseId: course.id, title: course.title, subtitle: course.subtitle, iconKey: course.iconKey, colorKey: course.colorKey),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({
    required this.courseId,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.colorKey,
  });

  final int courseId;
  final String title;
  final String subtitle;
  final String iconKey;
  final String colorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider(courseId));
    final color = colorForCourseKey(colorKey);
    final status = progressAsync.valueOrNull?.status;

    return FeatureCard(
      title: title,
      subtitle: subtitle,
      icon: iconForCourseKey(iconKey),
      color: color,
      trailing: status == 'completed'
          ? Icon(Icons.check_circle, color: color, size: 22)
          : status == 'in_progress'
              ? Text(
                  S.literal('In progress'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                )
              : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: courseId)),
      ),
    );
  }
}
