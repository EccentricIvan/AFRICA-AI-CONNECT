import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';

class HealthResourceContent {
  const HealthResourceContent({
    required this.titleKey,
    required this.subtitleKey,
    required this.iconKey,
    required this.readingText,
  });
  final String titleKey;
  final String subtitleKey;
  final String iconKey;
  final String readingText;

  factory HealthResourceContent.fromJson(Map<String, dynamic> json) {
    return HealthResourceContent(
      titleKey: json['titleKey'] as String,
      subtitleKey: json['subtitleKey'] as String,
      iconKey: json['iconKey'] as String,
      readingText: json['readingText'] as String,
    );
  }
}

/// Real curated content, shipped as a data asset (not hardcoded Dart) —
/// same convention as assets/skills/skills_content.json.
final healthResourcesContentProvider = FutureProvider<List<HealthResourceContent>>((ref) async {
  final raw = await rootBundle.loadString('assets/health/health_resources.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = decoded['resources'] as List<dynamic>;
  return list
      .map((r) => HealthResourceContent.fromJson(r as Map<String, dynamic>))
      .toList();
});

IconData _iconForResourceKey(String key) {
  switch (key) {
    case 'pregnant_woman':
      return Icons.pregnant_woman;
    case 'restaurant':
      return Icons.restaurant;
    case 'child_care':
      return Icons.child_care;
    case 'self_improvement':
      return Icons.self_improvement;
    default:
      return Icons.menu_book;
  }
}

const _facilityTypes = ['Clinic', 'Hospital', 'Pharmacy', 'Maternity', 'Other'];

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  void _openAddFacilitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddFacilitySheet(),
    );
  }

  void _openResourceOverlay(BuildContext context, WidgetRef ref, HealthResourceContent resource) {
    String t(String key) => S.tr(context, ref, key);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
              Text(t(resource.titleKey), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                t(resource.subtitleKey),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    resource.readingText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    final resourcesAsync = ref.watch(healthResourcesContentProvider);
    final facilitiesAsync = ref.watch(healthFacilitiesProvider);

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
                    _HealthHero(
                      t: t,
                      facilityCount: facilitiesAsync.valueOrNull?.length ?? 0,
                      resourceCount: resourcesAsync.valueOrNull?.length ?? 0,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(t('health_resources')),
                    const SizedBox(height: 4),
                    Text(t('trusted_health_desc'), style: TextStyle(fontSize: 13, color: AppColors.of(context).textHint)),
                    const SizedBox(height: 14),
                    resourcesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => Text(S.literal('Could not load health resources.')),
                      data: (resources) => Column(
                        children: resources.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ResourceCard(
                            resource: r,
                            t: t,
                            onTap: () => _openResourceOverlay(context, ref, r),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _SectionLabel(t('nearby_services_title'))),
                        TextButton.icon(
                          onPressed: () => _openAddFacilitySheet(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(S.literal('Add')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(t('nearby_services_sub'), style: TextStyle(fontSize: 13, color: AppColors.of(context).textHint)),
                    const SizedBox(height: 14),
                    facilitiesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => Text(S.literal('Could not load nearby services.')),
                      data: (facilities) {
                        if (facilities.isEmpty) {
                          return Text(S.literal('No nearby services added yet — be the first to add one!'));
                        }
                        return Column(
                          children: facilities.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FacilityCard(facility: f),
                          )).toList(),
                        );
                      },
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x18142840),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x12142840)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back_rounded, color: ac.textPrimary, size: 20),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ac.textPrimary),
                ),
                Text(
                  t('thrive_desc'),
                  style: TextStyle(fontSize: 12, color: ac.textHint),
                ),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.healthColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded, color: AppColors.healthColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _HealthHero extends StatelessWidget {
  const _HealthHero({required this.t, required this.facilityCount, required this.resourceCount});
  final String Function(String) t;
  final int facilityCount;
  final int resourceCount;

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
        border: Border.all(color: AppColors.healthColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('your_health_matters'),
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: ac.textPrimary, height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('your_health_matters_desc'),
                  style: TextStyle(fontSize: 13, color: ac.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HealthChip(Icons.location_on_rounded, '$facilityCount ${t("nearby_services_title")}', AppColors.healthColor),
                    const SizedBox(width: 8),
                    _HealthChip(Icons.menu_book_rounded, '$resourceCount ${t("health_resources")}', AppColors.financeColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.healthColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.healthColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.favorite_rounded, color: AppColors.healthColor, size: 30),
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.t, required this.onTap});
  final HealthResourceContent resource;
  final String Function(String) t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x12142840),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x15142840)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.healthColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconForResourceKey(resource.iconKey), color: AppColors.healthColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(resource.titleKey),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ac.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t(resource.subtitleKey),
                    style: TextStyle(fontSize: 12, color: ac.textHint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0x55142840), size: 20),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.facility});
  final HealthFacility facility;

  Future<void> _openDirections() async {
    final query = Uri.encodeComponent(
      facility.address != null ? '${facility.name}, ${facility.address}' : facility.name,
    );
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x12142840),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x15142840)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.healthColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_hospital, color: AppColors.healthColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ac.textPrimary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(facility.type, style: TextStyle(fontSize: 12, color: ac.textHint)),
                    if (facility.address != null) ...[
                      const Text('  ·  ', style: TextStyle(fontSize: 12, color: Color(0x44142840))),
                      Expanded(
                        child: Text(
                          facility.address!,
                          style: TextStyle(fontSize: 12, color: ac.textHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openDirections,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 20),
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
      style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
        color: AppColors.of(context).textHint,
      ),
    );
  }
}

// ─────────────────────────── Add nearby service form ───────────────────────

class _AddFacilitySheet extends ConsumerStatefulWidget {
  const _AddFacilitySheet();

  @override
  ConsumerState<_AddFacilitySheet> createState() => _AddFacilitySheetState();
}

class _AddFacilitySheetState extends ConsumerState<_AddFacilitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _type = _facilityTypes.first;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(healthFacilitiesDaoProvider).addFacility(
          name: _nameController.text.trim(),
          type: _type,
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
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
                Text(S.literal('Add a Nearby Service'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: S.literal('Facility name')),
                  validator: (v) => (v == null || v.trim().isEmpty) ? S.literal('Enter a name') : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _facilityTypes.map((t) {
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
                  controller: _addressController,
                  decoration: InputDecoration(hintText: S.literal('Where it\'s located (address)')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.healthColor),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(S.literal('Add Service')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
