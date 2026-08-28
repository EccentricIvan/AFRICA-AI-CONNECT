import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    final resources = [
      _Resource(
        t('maternal_health'),
        t('maternal_health_desc'),
        Icons.pregnant_woman,
        AppColors.thriveColor,
      ),
      _Resource(
        t('nutrition_guide'),
        t('nutrition_guide_desc'),
        Icons.restaurant,
        AppColors.healthColor,
      ),
      _Resource(
        t('child_health'),
        t('child_health_desc'),
        Icons.child_care,
        AppColors.financeColor,
      ),
      _Resource(
        t('mental_wellness'),
        t('mental_wellness_desc'),
        Icons.spa,
        AppColors.wellbeingColor,
      ),
    ];

    const nearby = [
      _Facility(
        'Nakasero Hospital',
        'Health Centre IV',
        2.3,
        AppColors.healthColor,
        Icons.local_hospital,
      ),
      _Facility(
        "Mulago Women's Clinic",
        'Specialised',
        4.1,
        AppColors.thriveColor,
        Icons.medical_services,
      ),
      _Facility(
        'Community Health Post',
        'Health Centre II',
        0.8,
        AppColors.financeColor,
        Icons.health_and_safety,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _HealthAppBar(t: t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _HealthHero(t: t),
                    const SizedBox(height: 24),
                    _SectionLabel(t('health_resources')),
                    const SizedBox(height: 4),
                    Text(
                      t('trusted_health_desc'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...resources.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ResourceCard(resource: r),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(t('nearby_services_title')),
                    const SizedBox(height: 4),
                    Text(
                      t('nearby_services_sub'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...nearby.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FacilityCard(facility: f, t: t),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthAppBar extends StatelessWidget {
  const _HealthAppBar({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x183A2E29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x123A2E29)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => context.go('/'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('health'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  t('thrive_desc'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.healthColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.healthColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthHero extends StatelessWidget {
  const _HealthHero({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.healthColor.withValues(alpha: 0.2),
            AppColors.thriveColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.healthColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('your_health_matters'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('your_health_matters_desc'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HealthChip(
                      Icons.location_on_rounded,
                      '3 ${t("nearby_services_title")}',
                      AppColors.healthColor,
                    ),
                    const SizedBox(width: 8),
                    _HealthChip(
                      Icons.menu_book_rounded,
                      '4 ${t("health_resources")}',
                      AppColors.financeColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.healthColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.healthColor.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.healthColor,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final _Resource resource;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x123A2E29),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x153A2E29)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: resource.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(resource.icon, color: resource.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resource.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0x553A2E29),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility, required this.t});
  final _Facility facility;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x123A2E29),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x153A2E29)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: facility.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(facility.icon, color: facility.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      facility.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const Text(
                      '  ·  ',
                      style: TextStyle(fontSize: 12, color: Color(0x443A2E29)),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: facility.color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${facility.distKm} ${t("km_away")}',
                      style: TextStyle(
                        fontSize: 12,
                        color: facility.color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textHint,
      ),
    );
  }
}

class _Resource {
  const _Resource(this.title, this.subtitle, this.icon, this.color);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _Facility {
  const _Facility(this.name, this.type, this.distKm, this.color, this.icon);
  final String name;
  final String type;
  final double distKm;
  final Color color;
  final IconData icon;
}
