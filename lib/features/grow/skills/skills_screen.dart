import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/feature_card.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                FeatureCard(
                  title: S.literal('Digital Literacy'),
                  subtitle: S.literal('Phone, internet, and computer basics'),
                  icon: Icons.computer,
                  color: AppColors.skillsColor,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                FeatureCard(
                  title: S.literal('Business Management'),
                  subtitle: S.literal('Planning, accounting, and operations'),
                  icon: Icons.business_center,
                  color: AppColors.earnColor,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                FeatureCard(
                  title: S.literal('Value Addition'),
                  subtitle: S.literal('Processing, packaging, and branding products'),
                  icon: Icons.inventory,
                  color: AppColors.marketplaceColor,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                FeatureCard(
                  title: S.literal('Communication Skills'),
                  subtitle: S.literal('Negotiation, presentation, and networking'),
                  icon: Icons.record_voice_over,
                  color: AppColors.communityColor,
                  onTap: () {},
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
