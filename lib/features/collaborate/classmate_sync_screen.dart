import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/lan_discovery.dart';
import '../../collaboration/sync/class_crypto.dart' show schoolTag;
import '../../collaboration/sync/selective_sync_manager.dart' show TeacherEndpoint;
import '../../core/theme/app_colors.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../l10n/app_locale.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/studio_page.dart';
import '../teacher/class_providers.dart';
import 'classmate_share_cards.dart';

/// Student-to-student sharing, opened from My notes. Two options only:
/// **Share** notes to a classmate, or **Receive** notes from one. Everything
/// uses a short code — no addresses. A learner must have joined their class
/// through the teacher first (that is what keys the notes); until then this
/// points them to Sync.
class ClassmateSyncScreen extends ConsumerStatefulWidget {
  const ClassmateSyncScreen({super.key});

  @override
  ConsumerState<ClassmateSyncScreen> createState() =>
      _ClassmateSyncScreenState();
}

class _ClassmateSyncScreenState extends ConsumerState<ClassmateSyncScreen> {
  LanDiscoveryService? _service;
  List<LanPeer> _peers = const [];
  String? _myTag;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (kIsWeb) return;
    final student = await ref.read(activeStudentProvider.future);
    final me = await ref.read(dbProvider).classSyncDao.identity();
    if (!mounted) return;
    _myTag = schoolTag(me.schoolId);
    final service = LanDiscoveryService(
      displayName: student?.name ?? 'Learner',
      points: student?.totalPoints ?? 0,
      schoolTag: _myTag,
    );
    try {
      await service.start();
      service.peers.listen((list) {
        if (mounted) setState(() => _peers = list);
      });
      if (mounted) {
        setState(() => _service = service);
      } else {
        service.dispose();
      }
    } on SocketException {
      service.dispose();
    }
  }

  /// Classmates of this school sharing their teacher's notes nearby.
  List<TeacherEndpoint> get _classmates => [
    for (final p in _peers)
      if (p.isClassmateShare && (_myTag == null || p.schoolTag == _myTag))
        (address: p.address, port: p.syncPort!),
  ];

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final studentAsync = ref.watch(activeStudentProvider);
    final classes = ref.watch(classGroupsProvider).valueOrNull ?? const [];
    final classId = studentAsync.valueOrNull?.classGroupId;
    ClassGroup? group;
    for (final c in classes) {
      if (c.id == classId) group = c;
    }
    final joined = group != null && group.joined;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: StudioAppBar(
        title: tr(context, 'Share notes'),
        subtitle: tr(context, 'With a classmate'),
        icon: Icons.group_rounded,
        iconColor: AppColors.accentViolet,
        showBack: true,
      ),
      body: MaxWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!joined)
              StudioCard(
                accent: AppColors.accentOrange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'Join your class first'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        'Ask your teacher for the class code and join on Sync. '
                        'Then you can share notes with classmates here.',
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: ac.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              GetFromClassmateCard(
                group: group,
                found: _classmates,
                learnerName: studentAsync.valueOrNull?.name ?? '',
              ),
              const SizedBox(height: 16),
              ShareWithClassmatesCard(group: group, discovery: _service),
            ],
          ],
        ),
      ),
    );
  }
}
