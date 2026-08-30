import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';

class MentorshipScreen extends ConsumerWidget {
  const MentorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    const mentors = [
      _Mentor('Amina B.', 'Agriculture & Agribusiness', 'Kampala', 12, AppColors.healthColor),
      _Mentor('Florence N.', 'Financial Management', 'Jinja', 8, AppColors.financeColor),
      _Mentor('Esther K.', 'Digital Marketing', 'Mbale', 5, AppColors.chatColor),
      _Mentor('Harriet O.', 'Entrepreneurship', 'Kampala', 15, AppColors.earnColor),
    ];

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
                    ...mentors.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MentorCard(mentor: m, t: t),
                    )),
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

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor, required this.t});
  final _Mentor mentor;
  final String Function(String) t;

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
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: mentor.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mentor.color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                mentor.name[0],
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: mentor.color,
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
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.mentorshipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mentorshipColor.withValues(alpha: 0.3)),
              ),
              child: Text(
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

class _BecomeMentorCard extends StatelessWidget {
  const _BecomeMentorCard({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
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
            onTap: () {},
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

class _Mentor {
  const _Mentor(this.name, this.expertise, this.location, this.yearsExp, this.color);
  final String name;
  final String expertise;
  final String location;
  final int yearsExp;
  final Color color;
}
