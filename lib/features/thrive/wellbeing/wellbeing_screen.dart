import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/helpline_sheet.dart';

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellbeing')),
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
                        AppColors.wellbeingColor.withValues(alpha: 0.12),
                        AppColors.thriveColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            AppColors.wellbeingColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your wellbeing matters',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall),
                            const SizedBox(height: 6),
                            Text(
                              'Resources for self-care, emotional support, and building resilience.',
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
                          color:
                              AppColors.wellbeingColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.spa,
                            color: AppColors.wellbeingColor, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Self-Care',
                  subtitle: 'Daily practices for a healthier mind',
                ),
                const SizedBox(height: 12),
                FeatureCard(
                  title: 'Stress Management',
                  subtitle: 'Techniques to manage daily stress and anxiety',
                  icon: Icons.self_improvement,
                  color: AppColors.wellbeingColor,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                FeatureCard(
                  title: 'Positive Affirmations',
                  subtitle: 'Daily encouragement and confidence building',
                  icon: Icons.auto_awesome,
                  color: AppColors.earnColor,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                FeatureCard(
                  title: 'Support Resources',
                  subtitle: 'Helplines, counselling, and safe spaces',
                  icon: Icons.support_agent,
                  color: AppColors.communityColor,
                  onTap: () => showHelplineSheet(context),
                ),
                const SizedBox(height: 24),
                _SafetyCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety & Support',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'If you or someone you know needs help, trusted support is available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showHelplineSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Get Help'),
          ),
        ],
      ),
    );
  }
}
