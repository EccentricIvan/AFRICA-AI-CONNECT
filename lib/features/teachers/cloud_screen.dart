import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/cloud/cloud_link.dart';
import '../../collaboration/cloud/cloud_sync.dart';
import '../../collaboration/cloud/http_cloud_sync.dart' show CloudError;
import '../../core/theme/app_colors.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/studio_page.dart';
import '../admin/admin_service.dart';
import '../teacher/teacher_profiles.dart' show activeTeacherIdProvider;

final _pendingProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(cloudOutboxProvider).pending(),
);

final _learnersProvider = FutureProvider.autoDispose<List<Student>>(
  (ref) => ref.watch(dbProvider).select(ref.watch(dbProvider).students).get(),
);

/// Teachers → School cloud: link this device to the school's cloud with a
/// one-time code, send what is queued, and bring a learner's work back on a
/// replacement device. The Admin also makes codes and revokes devices.
/// Off unless linked; nothing here is needed for learning.
class CloudScreen extends ConsumerStatefulWidget {
  const CloudScreen({super.key});

  @override
  ConsumerState<CloudScreen> createState() => _CloudScreenState();
}

class _CloudScreenState extends ConsumerState<CloudScreen> {
  final _address = TextEditingController();
  final _code = TextEditingController();
  final _label = TextEditingController();
  String _role = 'learner';
  bool _busy = false;
  String? _note;
  List<CloudDevice>? _devices;

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final note = await action();
      if (mounted) setState(() => _note = note);
    } on CloudError catch (e) {
      if (mounted) setState(() => _note = e.message);
    } catch (_) {
      if (mounted) setState(() => _note = 'Could not reach the school cloud');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  CloudLinkService get _service => ref.read(cloudLinkServiceProvider);

  Future<void> _enroll() => _run(() async {
    final link = await _service.enroll(
      address: _address.text,
      code: _code.text,
      role: _role,
      label: _label.text,
    );
    _code.clear();
    return 'Linked to ${link.schoolName}';
  });

  Future<void> _send() => _run(() async {
    final outbox = ref.read(cloudOutboxProvider);
    final sent = await outbox.flush();
    await _service.noteSent(outbox.lastError);
    ref.invalidate(_pendingProvider);
    return outbox.lastError ?? 'Sent $sent';
  });

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink this device?'),
        content: const Text(
          'Records stay on this device and queued. Nothing is deleted from the school cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await _service.unlink();
      return 'Unlinked';
    });
  }

  Future<void> _issue(String role, {Student? recovers}) => _run(() async {
    final uuid = recovers?.uuid;
    final code = await _service.issueCode(
      role: role,
      learnerUuids: uuid == null ? const [] : [uuid],
    );
    if (!mounted) return null;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          recovers == null ? 'Code for a $role device' : 'Recovery code',
        ),
        content: SelectableText(
          code,
          style: const TextStyle(fontSize: 22, letterSpacing: 2),
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    return null;
  });

  Future<void> _loadDevices() => _run(() async {
    final list = await _service.devices();
    if (mounted) setState(() => _devices = list);
    return null;
  });

  Future<void> _revoke(CloudDevice d) => _run(() async {
    await _service.revoke(d.key);
    final list = await _service.devices();
    if (mounted) setState(() => _devices = list);
    return 'Revoked';
  });

  Future<Student?> _pickLearner({bool needsUuid = true}) async {
    final learners = [
      for (final s in await ref.read(_learnersProvider.future))
        if (!needsUuid || s.uuid != null) s,
    ];
    if (!mounted) return null;
    if (learners.isEmpty) {
      setState(() => _note = 'No learners from the school’s records');
      return null;
    }
    return showDialog<Student>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Learner'),
        children: [
          for (final s in learners)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: Text(s.name),
            ),
        ],
      ),
    );
  }

  Future<void> _backUp() => _run(() async {
    await _service.backUpTeacherDevice();
    return 'Teacher device backed up';
  });

  Future<void> _restore() async {
    final List<({int id, String label, String at})> backups;
    try {
      backups = await _service.teacherBackups();
    } on CloudError catch (e) {
      setState(() => _note = e.message);
      return;
    }
    if (!mounted) return;
    if (backups.isEmpty) {
      setState(() => _note = 'No teacher-device backups');
      return;
    }
    final passphrase = TextEditingController();
    int? chosen = backups.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Take over a teacher device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: chosen,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Backup'),
                items: [
                  for (final b in backups)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text(
                        '${b.label.isEmpty ? 'Teacher device' : b.label} · ${b.at.split('T').first}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => set(() => chosen = v),
              ),
              TextField(
                controller: passphrase,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Standby passphrase',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Take over'),
            ),
          ],
        ),
      ),
    );
    final text = passphrase.text;
    passphrase.dispose();
    if (ok != true || chosen == null) return;
    await _run(() async {
      final r = await _service.restoreTeacherDevice(
        chosen!,
        text,
        ownerTeacherId: ref.read(activeTeacherIdProvider),
      );
      if (r.error != null) return r.error;
      final relink = await _service.link() == null
          ? ' Link this device to the school cloud again.'
          : '';
      return 'This is now the teacher device: ${r.classes} classes, '
          '${r.notes} notes.$relink';
    });
  }

  Future<void> _recover() async {
    final s = await _pickLearner();
    if (s == null) return;
    await _run(() async {
      final n = await _service.recoverLearner(s);
      return '${s.name}: $n answer${n == 1 ? '' : 's'} brought back';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final link = ref.watch(cloudLinkProvider).valueOrNull;
    final pending = ref.watch(_pendingProvider).valueOrNull;
    final admin =
        link?.role == 'admin' && ref.watch(adminSessionProvider) != null;
    final small = TextStyle(fontSize: 12.5, color: ac.textSecondary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const StudioAppBar(
        title: 'School cloud',
        subtitle: 'Optional backup',
        icon: Icons.cloud_outlined,
        showBack: true,
      ),
      body: MaxWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (link == null)
              StudioCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not linked',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    if (pending != null && pending > 0)
                      Text('$pending records waiting', style: small),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Server address',
                        hintText: 'https://cloud.school.ug',
                      ),
                    ),
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Code'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Device'),
                      items: const [
                        DropdownMenuItem(
                          value: 'learner',
                          child: Text('Learner device'),
                        ),
                        DropdownMenuItem(
                          value: 'teacher',
                          child: Text('Teacher device'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    TextField(
                      controller: _label,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Device name',
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _enroll,
                      child: const Text('Link'),
                    ),
                  ],
                ),
              )
            else ...[
              StudioCard(
                accent: AppColors.accentGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.schoolName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    Text('${link.role} · ${link.baseUrl}', style: small),
                    if (pending != null)
                      Text(
                        pending == 0
                            ? 'Everything sent'
                            : '$pending record${pending == 1 ? '' : 's'} waiting',
                        style: small,
                      ),
                    if (link.lastError case final e?)
                      Text(
                        e,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy ? null : _send,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Send now'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _recover,
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Bring back a learner’s work'),
                        ),
                        if (link.role != 'learner') ...[
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _backUp,
                            icon: const Icon(Icons.backup_outlined),
                            label: const Text('Back up this teacher device'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _restore,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Take over a teacher device'),
                          ),
                        ],
                        TextButton(
                          onPressed: _busy ? null : _unlink,
                          child: const Text('Unlink'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (admin) ...[
                const SizedBox(height: 16),
                StudioCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Codes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ac.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final role in const ['learner', 'teacher'])
                            OutlinedButton(
                              onPressed: _busy ? null : () => _issue(role),
                              child: Text('Code for a $role device'),
                            ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    final s = await _pickLearner();
                                    if (s != null) {
                                      await _issue('learner', recovers: s);
                                    }
                                  },
                            child: const Text('Recovery code'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StudioCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Devices',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ac.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _loadDevices,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                      for (final d in _devices ?? const <CloudDevice>[])
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(d.label.isEmpty ? d.role : d.label),
                          subtitle: Text(
                            '${d.role} · ${d.status} · ${d.key.substring(0, 8)}',
                          ),
                          trailing: d.status == 'active'
                              ? TextButton(
                                  onPressed: _busy ? null : () => _revoke(d),
                                  child: const Text('Revoke'),
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ],
            if (_note != null) ...[
              const SizedBox(height: 12),
              Text(_note!, style: small),
            ],
          ],
        ),
      ),
    );
  }
}
