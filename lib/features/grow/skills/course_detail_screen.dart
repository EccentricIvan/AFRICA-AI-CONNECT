import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';

IconData iconForCourseKey(String key) {
  switch (key) {
    case 'computer':
      return Icons.computer;
    case 'business_center':
      return Icons.business_center;
    case 'inventory':
      return Icons.inventory;
    case 'record_voice_over':
      return Icons.record_voice_over;
    default:
      return Icons.school;
  }
}

Color colorForCourseKey(String key) {
  switch (key) {
    case 'skills':
      return AppColors.skillsColor;
    case 'earn':
      return AppColors.earnColor;
    case 'marketplace':
      return AppColors.marketplaceColor;
    case 'community':
      return AppColors.communityColor;
    default:
      return AppColors.skillsColor;
  }
}

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseProvider(courseId));
    final progressAsync = ref.watch(courseProgressProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: Text(S.literal('Course'))),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load this course.'))),
        data: (course) {
          if (course == null) {
            return Center(child: Text(S.literal('This course is no longer available.')));
          }
          final color = colorForCourseKey(course.colorKey);
          final progress = progressAsync.valueOrNull;
          final percent = progress?.progressPercent ?? 0.0;
          final status = progress?.status ?? 'not_started';

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
                          child: Icon(iconForCourseKey(course.iconKey), color: color, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
                              Text(course.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      S.literal('${course.lessonCount} lessons'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: status == 'completed'
                            ? null
                            : () => ref.read(coursesDaoProvider).advanceProgress(courseId),
                        style: ElevatedButton.styleFrom(backgroundColor: color),
                        child: Text(
                          status == 'completed'
                              ? S.literal('Completed')
                              : status == 'in_progress'
                                  ? S.literal('Continue')
                                  : S.literal('Start Course'),
                        ),
                      ),
                    ),
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
