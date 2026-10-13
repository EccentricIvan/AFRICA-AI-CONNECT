import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/offline/offline_readiness.dart';
import '../../shared/widgets/studio_page.dart';
import '../assignments/assignments_screens.dart' show formatWhen;

/// Before leaving school: whether everything the class has is on this
/// device, what work is open, and the space it takes. Sync now (above it)
/// fetches what is missing; a PDF download that stopped carries on.
class OfflineReadinessCard extends ConsumerWidget {
  const OfflineReadinessCard({super.key, required this.classId});

  final int classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    final r = ref.watch(offlineReadinessProvider(classId)).valueOrNull;
    if (r == null) return const SizedBox.shrink();
    final small = TextStyle(fontSize: 12.5, color: ac.textSecondary);
    final last = r.lastSync;
    return StudioCard(
      accent: r.ready ? AppColors.accentGreen : AppColors.accentOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.ready ? Icons.offline_pin_rounded : Icons.cloud_off_rounded,
                size: 18,
                color: r.ready ? AppColors.accentGreen : AppColors.accentOrange,
              ),
              const SizedBox(width: 8),
              Text(
                r.ready ? 'Ready for offline' : 'Not ready for offline',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            last == null
                ? 'Never synced'
                : 'Last sync ${formatWhen(last.toUtc())}',
            style: small,
          ),
          Text(
            '${r.subjects} subject${r.subjects == 1 ? '' : 's'} · '
            '${r.pdfsHeld} PDF${r.pdfsHeld == 1 ? '' : 's'} on this device',
            style: small,
          ),
          if (r.pdfsMissing > 0)
            Text(
              '${r.pdfsMissing} PDF${r.pdfsMissing == 1 ? '' : 's'} missing '
              '(${formatBytes(r.missingBytes)}'
              '${r.partialBytes > 0 ? ', ${formatBytes(r.partialBytes)} downloaded' : ''})',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.accentOrange,
              ),
            ),
          Text(
            'Assignments: ${r.toDo} to do · ${r.awaitingSync} waiting for Sync'
            ' · ${r.graded} graded',
            style: small,
          ),
          if (r.help > 0)
            Text('Help from your teacher: ${r.help}', style: small),
          Text(
            'Storage: PDFs ${formatBytes(r.pdfBytes)} · '
            'records ${formatBytes(r.databaseBytes)}',
            style: small,
          ),
        ],
      ),
    );
  }
}
