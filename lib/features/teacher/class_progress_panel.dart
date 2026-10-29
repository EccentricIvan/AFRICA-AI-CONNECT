import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collaboration/sync/progress_report.dart';
import '../../core/policy/policy.dart';
import '../../core/theme/app_colors.dart';
import '../../curriculum/curriculum_models.dart';
import '../../services/custom_subject_service.dart';
import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';
import '../../services/assignments/learner_support.dart';
import '../../shared/widgets/studio_page.dart';
import 'class_providers.dart';
import 'teacher_profiles.dart';
import 'teaching_scope.dart';

/// Latest reports from members' devices for one class, live from SQLite.
final memberReportsProvider = StreamProvider.autoDispose
    .family<List<({ProgressReport report, String receivedAt})>, String>(
      (ref, classUuid) =>
          ref.watch(dbProvider).classSyncDao.watchMemberReports(classUuid),
    );

/// Extra help this device sent to a class's learners, newest first.
final _sentSupportProvider = StreamProvider.autoDispose
    .family<List<LearnerSupportItem>, String>(
      (ref, classUuid) =>
          ref.watch(learnerSupportProvider).watchSent(classUuid),
    );

/// The subjects the signed-in teacher may send a class's learners help in.
final _supportSubjectsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, classUuid) async {
      final me = ref.watch(activeTeacherIdProvider);
      if (me == null) return const [];
      final policy = ref.watch(policyProvider);
      final out = <String>{};
      for (final a in await TeachingScope(
        ref.watch(dbProvider),
      ).assignments(me)) {
        if (a.classGroupUuid == classUuid &&
            await policy.can(
              TeacherActor(me),
              SupportLearner(a.subjectId, classUuid),
            )) {
          out.add(a.subjectId);
        }
      }
      return out.toList()..sort();
    });

/// How a class is doing, from its members' own devices: each learner's
/// latest report, as sent when they last synced with this teacher device.
/// Stored on this device, so it shows whether or not sharing is on.
class ClassProgressPanel extends ConsumerWidget {
  const ClassProgressPanel({super.key, required this.group});

  final ClassGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    final uuid = group.groupUuid;
    final rows = uuid == null
        ? const <({ProgressReport report, String receivedAt})>[]
        : ref.watch(memberReportsProvider(uuid)).valueOrNull ?? const [];

    final names = {
      for (final s
          in ref.watch(mergedSubjectsProvider).valueOrNull ?? const <Subject>[])
        s.id: s.name,
    };
    final levels = [for (final r in rows) ?r.report.meanLevel];
    final classMean = levels.isEmpty
        ? null
        : (levels.reduce((a, b) => a + b) / levels.length).round();

    return StudioCard(
      accent: AppColors.accentGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class progress · ${classLabel(group)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rows.isEmpty
                ? 'No reports yet'
                : '${rows.length} learner${rows.length == 1 ? '' : 's'} reported'
                      '${classMean == null ? '' : ' · class mastery $classMean%'}',
            style: TextStyle(fontSize: 12, color: ac.textSecondary),
          ),
          for (final r in rows)
            _MemberRow(
              classUuid: uuid!,
              report: r.report,
              at: r.receivedAt,
              subjectName: (id) => names[id] ?? id.replaceAll('_', ' '),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.classUuid,
    required this.report,
    required this.at,
    required this.subjectName,
  });

  final String classUuid;
  final ProgressReport report;
  final String at;
  final String Function(String id) subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    final r = report;
    final support = [
      for (final i
          in ref.watch(_sentSupportProvider(classUuid)).valueOrNull ??
              const <LearnerSupportItem>[])
        if (i.memberKey == r.memberKey) i,
    ];
    final subjects =
        ref.watch(_supportSubjectsProvider(classUuid)).valueOrNull ??
        const <String>[];
    // Reports without the device clock come from builds before this one.
    final device = [
      if (r.sentAt == null) 'last sync from an older app',
      ?clockNote(r.clockOffset(at)),
    ];
    final accuracy = r.practiceAttempted == 0
        ? null
        : (100 * r.practiceCorrect / r.practiceAttempted).round();
    final weak = [
      for (final t in r.topics)
        if (t.level < 50) t.topic,
    ];
    final facts = [
      if (r.meanLevel != null) 'mastery ${r.meanLevel}%',
      '${r.lessonsCompleted} lessons',
      if (accuracy != null) 'practice $accuracy% right',
      '${r.points} pts',
      if (r.streakDays > 0) '${r.streakDays}-day streak',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              Text(
                'synced ${_when(at)}',
                style: TextStyle(fontSize: 11, color: ac.textHint),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            facts.join(' · '),
            style: TextStyle(fontSize: 12, color: ac.textSecondary),
          ),
          if (r.enrolled.isNotEmpty)
            Text(
              'Takes: ${r.enrolled.map(subjectName).join(', ')}',
              style: TextStyle(fontSize: 12, color: ac.textSecondary),
            ),
          if (weak.isNotEmpty || r.weaknesses.isNotEmpty)
            Text(
              'Needs help: ${{...weak.take(3), ...r.weaknesses.take(2)}.join(', ')}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentOrange,
              ),
            ),
          if (r.quizzes.isNotEmpty)
            Text(
              'Quizzes: ${r.quizzes.take(4).map(_quiz).join(', ')}',
              style: TextStyle(fontSize: 12, color: ac.textSecondary),
            ),
          if (device.isNotEmpty)
            Text(
              device.join(' · '),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accentOrange,
              ),
            ),
          for (final i in support)
            _SupportLine(item: i, report: r, subjectName: subjectName),
          if (subjects.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _SendSupportDialog(
                    classUuid: classUuid,
                    report: r,
                    subjects: subjects,
                    subjectName: subjectName,
                  ),
                ),
                icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                label: const Text('Send help'),
              ),
            ),
          if (r.topics.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in r.topics.take(8))
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${t.topic} ${t.level}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _quiz(
    ({String subject, String topic, int correct, int total, int? tutorUsed}) q,
  ) {
    final used = q.tutorUsed ?? 0;
    return '${q.topic} ${q.correct}/${q.total}'
        '${used > 0 ? ' (tutor used $used)' : ''}';
  }

  static String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}

/// One item of extra help: what was sent, whether the learner opened it,
/// and their quiz score on its topic then and now.
class _SupportLine extends ConsumerWidget {
  const _SupportLine({
    required this.item,
    required this.report,
    required this.subjectName,
  });

  final LearnerSupportItem item;
  final ProgressReport report;
  final String Function(String id) subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    final ack = report.support.where((s) => s.id == item.uuid).firstOrNull;
    final p = LearnerSupportService.progress(item, report);
    final score = switch ((p.before, p.now)) {
      (null, null) => null,
      (final b?, null) => 'quiz ${percent(b.correct, b.total)}%',
      (null, final n?) => 'quiz now ${percent(n.correct, n.total)}%',
      (final b?, final n?) =>
        'quiz ${percent(b.correct, b.total)}% → '
            '${percent(n.correct, n.total)}% '
            '(${_signed(percent(n.correct, n.total) - percent(b.correct, b.total))})',
    };
    final used = p.now?.tutorUsed ?? 0;
    final facts = [
      subjectName(item.subjectId),
      if (item.topic.isNotEmpty) item.topic,
      ack?.doneAt != null
          ? 'done'
          : ack?.openedAt != null
          ? 'opened'
          : 'not opened yet',
      ?score,
      if (used > 0) 'tutor used $used',
    ];
    return Row(
      children: [
        Icon(Icons.volunteer_activism_outlined, size: 14, color: ac.textHint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Help: ${facts.join(' · ')}',
            style: TextStyle(fontSize: 12, color: ac.textSecondary),
          ),
        ),
        IconButton(
          tooltip: 'Withdraw',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          onPressed: () => ref.read(learnerSupportProvider).withdraw(item.uuid),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  static String _signed(int n) => n > 0 ? '+$n' : '$n';
}

/// Extra help for one learner: a message, a note of the subject to read and
/// the quiz on one of its topics. It reaches only their device, at its next
/// Sync.
class _SendSupportDialog extends ConsumerStatefulWidget {
  const _SendSupportDialog({
    required this.classUuid,
    required this.report,
    required this.subjects,
    required this.subjectName,
  });

  final String classUuid;
  final ProgressReport report;
  final List<String> subjects;
  final String Function(String id) subjectName;

  @override
  ConsumerState<_SendSupportDialog> createState() => _SendSupportDialogState();
}

class _SendSupportDialogState extends ConsumerState<_SendSupportDialog> {
  final _message = TextEditingController();
  late String _subject = _weakestSubject();
  String? _note;
  String? _topic;
  bool _quiz = true;
  ({List<String> notes, List<String> topics})? _offer;

  /// The subject of the learner's lowest quiz score, when this teacher may
  /// help with it.
  String _weakestSubject() {
    final quizzes = [...widget.report.quizzes]
      ..sort(
        (a, b) =>
            percent(a.correct, a.total).compareTo(percent(b.correct, b.total)),
      );
    for (final q in quizzes) {
      if (widget.subjects.contains(q.subject)) return q.subject;
    }
    return widget.subjects.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final subject = _subject;
    final offer = await ref
        .read(learnerSupportProvider)
        .offerable(widget.classUuid, subject);
    if (!mounted || subject != _subject) return;
    // The learner's weakest topic first.
    final scores = {
      for (final q in widget.report.quizzes)
        if (q.subject == subject) q.topic: percent(q.correct, q.total),
    };
    final topics = [...offer.topics]
      ..sort((a, b) => (scores[a] ?? 101).compareTo(scores[b] ?? 101));
    setState(() {
      _offer = (notes: offer.notes, topics: topics);
      _topic = topics.where(scores.containsKey).firstOrNull;
      _note = null;
    });
  }

  String _label(String topic) {
    final q = widget.report.quizzes
        .where((q) => q.subject == _subject && q.topic == topic)
        .firstOrNull;
    return q == null ? topic : '$topic (${percent(q.correct, q.total)}%)';
  }

  Future<void> _send() async {
    final id = await ref
        .read(learnerSupportProvider)
        .send(
          classUuid: widget.classUuid,
          report: widget.report,
          teacherId: ref.read(activeTeacherIdProvider),
          subjectId: _subject,
          topic: _topic ?? '',
          documentTitle: _note,
          message: _message.text,
          quiz: _quiz && _topic != null,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (id == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a message, a note or a quiz')),
      );
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Sent · reaches ${widget.report.name} at Sync')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    return AlertDialog(
      title: Text('Help for ${widget.report.name}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: [
                  for (final id in widget.subjects)
                    DropdownMenuItem(
                      value: id,
                      child: Text(widget.subjectName(id)),
                    ),
                ],
                onChanged: (v) {
                  if (v == null || v == _subject) return;
                  setState(() {
                    _subject = v;
                    _offer = null;
                  });
                  _load();
                },
              ),
              if (offer == null)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                )
              else ...[
                DropdownButtonFormField<String?>(
                  key: ValueKey('topic-$_subject'),
                  initialValue: _topic,
                  decoration: const InputDecoration(labelText: 'Topic'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    for (final t in offer.topics)
                      DropdownMenuItem(value: t, child: Text(_label(t))),
                  ],
                  onChanged: (v) => setState(() => _topic = v),
                ),
                if (_topic != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _quiz,
                    onChanged: (v) => setState(() => _quiz = v ?? false),
                    title: const Text('Quiz'),
                  ),
                DropdownButtonFormField<String?>(
                  key: ValueKey('note-$_subject'),
                  initialValue: _note,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Note'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    for (final n in offer.notes)
                      DropdownMenuItem(
                        value: n,
                        child: Text(n, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _note = v),
                ),
              ],
              TextField(
                controller: _message,
                maxLines: 4,
                maxLength: kMaxSupportMessageChars,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send')),
      ],
    );
  }
}
