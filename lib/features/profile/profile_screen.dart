import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/section_header.dart';
import '../../db/providers/database_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () {})],
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
                _ProfileHeader(
                  name: user?.name ?? 'Friend',
                  role: user?.role,
                  location: user?.location,
                ),
                const SizedBox(height: 24),
                _StatsRow(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'My Progress',
                  subtitle: 'Track your learning and growth',
                ),
                const SizedBox(height: 12),
                _ProgressCards(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Achievements',
                  subtitle: 'Badges you\'ve earned',
                ),
                const SizedBox(height: 12),
                _AchievementsGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, this.role, this.location});
  final String name;
  final String? role;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.thriveColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person, color: AppColors.primary, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.earnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role ?? 'Member',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earnColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location ?? 'Location not set',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      const _Stat('Courses', '3', AppColors.learnColor),
      const _Stat('Points', '450', AppColors.earnColor),
      const _Stat('Streak', '7 days', AppColors.healthColor),
      const _Stat('Badges', '5', AppColors.growColor),
    ];

    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  s.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _ProgressCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Digital Skills', 0.65, AppColors.skillsColor),
      ('Financial Literacy', 0.40, AppColors.financeColor),
      ('Entrepreneurship', 0.25, AppColors.earnColor),
    ];

    return Column(
      children: items.map((p) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(p.$2 * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.$3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.$2,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(p.$3),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  static const _badges = [
    ('First Step', Icons.flag, AppColors.primary),
    ('Quick Learner', Icons.bolt, AppColors.earnColor),
    ('Community Star', Icons.star, AppColors.communityColor),
    ('Entrepreneur', Icons.rocket_launch, AppColors.marketplaceColor),
    ('Consistent', Icons.local_fire_department, AppColors.healthColor),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _badges.map((b) {
        return Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: b.$3.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: b.$3.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(b.$2, color: b.$3, size: 28),
              const SizedBox(height: 6),
              Text(
                b.$1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
