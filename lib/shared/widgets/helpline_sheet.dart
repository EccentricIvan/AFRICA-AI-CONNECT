import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

class _Helpline {
  const _Helpline(this.name, this.description, this.phone);
  final String name;
  final String description;
  final String? phone;
}

/// General emergency numbers only — these are the ones we can be
/// confident are accurate. Specialized mental-health / gender-based
/// violence helpline numbers for the app's target regions still need to
/// be sourced from a verified local directory before this list is
/// considered complete; do not add phone numbers here without
/// confirming them with an authoritative source first.
const _helplines = [
  _Helpline(
    'Uganda Police Emergency',
    'For immediate danger or a safety emergency',
    '999',
  ),
  _Helpline(
    'Uganda Emergency Services (alt.)',
    'Alternate national emergency line',
    '112',
  ),
  _Helpline(
    'Talk to someone you trust',
    'A family member, friend, or community leader can help you find '
        'local support even when a hotline isn\'t available.',
    null,
  ),
];

Future<void> showHelplineSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.shield, color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Text('Safety & Support', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'If you are in immediate danger, contact emergency services now.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ..._helplines.map((h) => _HelplineTile(helpline: h)),
          ],
        ),
      ),
    ),
  );
}

class _HelplineTile extends StatelessWidget {
  const _HelplineTile({required this.helpline});
  final _Helpline helpline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOverlay.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helpline.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(helpline.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (helpline.phone != null) ...[
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.call, size: 18),
              style: IconButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => launchUrl(Uri.parse('tel:${helpline.phone}')),
            ),
          ],
        ],
      ),
    );
  }
}
