import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/messaging/chat_room_screen.dart';

Color colorForMentorKey(String key) {
  switch (key) {
    case 'health':
      return AppColors.healthColor;
    case 'finance':
      return AppColors.financeColor;
    case 'chat':
      return AppColors.chatColor;
    case 'earn':
      return AppColors.earnColor;
    default:
      return AppColors.mentorshipColor;
  }
}

class MentorshipScreen extends ConsumerWidget {
  const MentorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);
    final mentorsAsync = ref.watch(mentorsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _GrowAppBar(t: t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _GrowHero(t: t),
                    const SizedBox(height: 24),
                    _SectionLabel(t('find_mentor_title')),
                    const SizedBox(height: 4),
                    Text(t('find_mentor_desc'), style: TextStyle(fontSize: 13, color: AppColors.of(context).textHint)),
                    const SizedBox(height: 14),
                    mentorsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => Text(S.literal('Could not load mentors. Try again later.')),
                      data: (mentors) => Column(
                        children: mentors.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MentorCard(mentor: m, t: t),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BecomeMentorCard(t: t),
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

class _GrowAppBar extends StatelessWidget {
  const _GrowAppBar({required this.t});
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
                  t('mentors'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ac.textPrimary),
                ),
                Text(
                  t('grow_desc'),
                  style: TextStyle(fontSize: 12, color: ac.textHint),
                ),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.mentorshipColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.diversity_1_rounded, color: AppColors.mentorshipColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _GrowHero extends StatelessWidget {
  const _GrowHero({required this.t});
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
            AppColors.mentorshipColor.withValues(alpha: 0.2),
            AppColors.growColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.mentorshipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('grow_with_guidance'),
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: ac.textPrimary, height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('grow_with_guidance_desc'),
                  style: TextStyle(fontSize: 13, color: ac.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.mentorshipColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.mentorshipColor.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.diversity_1_rounded, color: AppColors.mentorshipColor, size: 30),
          ),
        ],
      ),
    );
  }
}

class _MentorCard extends ConsumerStatefulWidget {
  const _MentorCard({required this.mentor, required this.t});
  final Mentor mentor;
  final String Function(String) t;

  @override
  ConsumerState<_MentorCard> createState() => _MentorCardState();
}

class _MentorCardState extends ConsumerState<_MentorCard> {
  bool _connecting = false;

  Future<void> _connect() async {
    setState(() => _connecting = true);
    final mentor = widget.mentor;
    final user = await ref.read(currentUserProvider.future);
    final myName = user?.name ?? S.literal('Me');

    final groupId = await ref.read(groupsDaoProvider).getOrCreateMentorGroup(
          mentorId: mentor.id,
          mentorName: mentor.name,
          colorKey: mentor.colorKey,
        );
    await ref.read(groupsDaoProvider).joinGroup(groupId: groupId, memberName: myName);

    final conversationId = await ref.read(messagingDaoProvider).getOrCreateConversation(
          type: 'mentor',
          subjectId: mentor.id,
          title: mentor.name,
          counterpartName: mentor.name,
        );

    if (!mounted) return;
    setState(() => _connecting = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mentor = widget.mentor;
    final t = widget.t;
    final ac = AppColors.of(context);
    final color = colorForMentorKey(mentor.colorKey);
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
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                mentor.name[0],
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ac.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  mentor.expertise,
                  style: TextStyle(fontSize: 12, color: ac.textSecondary),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: ac.textHint),
                    const SizedBox(width: 3),
                    Text(
                      '${mentor.location}  ·  ${mentor.yearsExp} ${t("yrs_experience")}',
                      style: TextStyle(fontSize: 11, color: ac.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _connecting ? null : _connect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mentorshipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mentorshipColor.withValues(alpha: 0.3)),
              ),
              child: _connecting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      t('connect_btn'),
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mentorshipColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BecomeMentorCard extends ConsumerWidget {
  const _BecomeMentorCard({required this.t});
  final String Function(String) t;

  Future<void> _openApplyDialog(BuildContext context, WidgetRef ref) async {
    final expertiseController = TextEditingController();
    final messageController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('apply_to_mentor')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: expertiseController,
              decoration: InputDecoration(labelText: S.literal('Your area of expertise')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(labelText: S.literal('Why do you want to mentor? (optional)')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.literal('Cancel')),
          ),
          FilledButton(
            onPressed: expertiseController.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(true),
            child: Text(S.literal('Submit')),
          ),
        ],
      ),
    );
    if (submitted != true) return;

    final user = await ref.read(currentUserProvider.future);
    await ref.read(mentorsDaoProvider).apply(
          applicantName: user?.name ?? S.literal('Applicant'),
          expertise: expertiseController.text.trim(),
          message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.literal('Application submitted — thank you!'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.growColor.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.growColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.growColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.growColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t('become_mentor_title').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.growColor, letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            t('share_knowledge'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            t('share_knowledge_desc'),
            style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openApplyDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.growColor,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.growColor.withValues(alpha: 0.35),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                t('apply_to_mentor'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
      style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
        color: AppColors.of(context).textHint,
      ),
    );
  }
}
