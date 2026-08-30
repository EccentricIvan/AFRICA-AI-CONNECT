import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../db/providers/database_provider.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../shared/widgets/home/home_ui.dart';
import '../../shared/widgets/learn/learn_ui.dart';

/// Copies a user-picked image into the app's own persistent documents
/// directory, mirroring Community's `_pickAndSaveGroupImage` — the OS
/// picker's temp/cache path isn't guaranteed to survive.
Future<String?> _pickAndSaveProfilePhoto() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) return null;

  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'profile_photos'));
  if (!await photosDir.exists()) await photosDir.create(recursive: true);

  final destPath = p.join(
    photosDir.path,
    '${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedPath)}',
  );
  await File(pickedPath).copy(destPath);
  return destPath;
}

/// Profile — a full-bleed gradient hero (matches Home's V3 tokens) with a
/// floating stats card bridging into the scrollable content below. Uses
/// `HomeUi.of(context)`/`LearnUi.of(context)` throughout, so it follows
/// the app's dark-mode setting like Home and Learn do.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _heroHeight = 330.0;
  static const _statsCardHeight = 108.0;

  void _openEditSheet(BuildContext context, {
    required String name,
    String? role,
    String? location,
    String? about,
    String? avatarPath,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HomeUi.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(
        name: name,
        role: role,
        location: location,
        about: about,
        avatarPath: avatarPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final ui = HomeUi.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final statsTop = topInset + _heroHeight - _statsCardHeight / 2;
    final contentTop = statsTop + _statsCardHeight + 16;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: AppColors.pageDecoration(context),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, contentTop, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileProgressBanner(),
                  const SizedBox(height: 28),
                  Text(
                    S.literal('Achievements'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ui.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.literal("Badges you've earned"),
                    style: TextStyle(
                      fontSize: 13,
                      color: ui.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _AchievementsGrid(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ProfileHeroBanner(
              topInset: topInset,
              name: user?.name ?? S.literal('Friend'),
              role: user?.role,
              location: user?.location,
              about: user?.about,
              avatarPath: user?.avatarPath,
              onBack: () => context.go('/'),
              onEdit: () => _openEditSheet(
                context,
                name: user?.name ?? '',
                role: user?.role,
                location: user?.location,
                about: user?.about,
                avatarPath: user?.avatarPath,
              ),
            ),
          ),
          Positioned(
            top: statsTop,
            left: 24,
            right: 24,
            child: const _StatsCard(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroBanner extends StatelessWidget {
  const _ProfileHeroBanner({
    required this.topInset,
    required this.name,
    required this.onBack,
    required this.onEdit,
    this.role,
    this.location,
    this.about,
    this.avatarPath,
  });

  final double topInset;
  final String name;
  final String? role;
  final String? location;
  final String? about;
  final String? avatarPath;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasAbout = about != null && about!.trim().isNotEmpty;
    final aboutLine =
        hasAbout ? about! : S.literal('Add a short bio to introduce yourself');
    final roleLine = role != null && role!.trim().isNotEmpty
        ? S.literal(role!)
        : S.literal('Add role');
    final locationLine = location != null && location!.trim().isNotEmpty
        ? location!
        : S.literal('Location not set');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeUi.accent, HomeUi.learn, HomeUi.thrive],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          // Trimmed from 20 to lift the avatar closer to the back/edit row —
          // frees just enough room for the about line below to fit without
          // growing the banner any taller than it needs to be.
          const SizedBox(height: 10),
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            child: ClipOval(
              child: avatarPath != null
                  ? Image.file(
                      File(avatarPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.white,
                      child: const Icon(
                        Icons.person_rounded,
                        color: HomeUi.accent,
                        size: 40,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Saira',
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: Text(
              aboutLine,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: hasAbout ? 0.88 : 0.7),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              _HeroFact(icon: Icons.badge_outlined, label: roleLine),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              _HeroFact(icon: Icons.location_on_rounded, label: locationLine),
            ],
          ),
        ],
      ),
    );
  }
}

/// One "icon + value" fact in the hero's role/location row — role and
/// location share this same shape so they read as a matched pair on one
/// line, separated by a small dot rather than sentence prefixes.
class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends ConsumerWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = HomeUi.of(context);
    final completedSkills = (ref.watch(allCourseProgressProvider).valueOrNull ?? const [])
        .where((p) => p.status == 'completed')
        .length;
    final communities = ref.watch(myGroupsProvider).valueOrNull?.length ?? 0;
    final badgesEarned = ref.watch(unlockedAchievementsProvider).length;
    final stats = [
      (S.literal('Skills Completed'), '$completedSkills', Icons.auto_awesome_outlined,
          HomeUi.learn),
      (S.literal('Communities Joined'), '$communities', Icons.groups_outlined, HomeUi.grow),
      (S.literal('Badges Earned'), '$badgesEarned', Icons.emoji_events_outlined,
          HomeUi.thrive),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(HomeUi.radiusCard),
        boxShadow: ui.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
        border: ui.isDark ? Border.all(color: ui.border) : null,
      ),
      child: Row(
        children: [
          for (final s in stats)
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.$4.withValues(alpha: 0.12),
                    ),
                    child: Icon(s.$3, size: 15, color: s.$4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontFamily: 'Saira',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: ui.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Learn's own progress-banner shell (stat row + streak strip), reused
/// for Profile's own "streak progress" stat set and an enlarged copy of
/// Home's streak card instead of Learn's "next milestone" bar.
class _ProfileProgressBanner extends ConsumerWidget {
  const _ProfileProgressBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = LearnUi.of(context);
    final stats = ref.watch(userStatsProvider).valueOrNull;
    final hitDays = ref.watch(currentWeekActivityProvider).valueOrNull ??
        const [false, false, false, false, false, false, false];
    final inProgress = (ref.watch(allCourseProgressProvider).valueOrNull ?? const [])
        .where((p) => p.status == 'in_progress')
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(LearnUi.radiusCard),
        boxShadow: ui.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.literal('Your Streak Progress'),
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ui.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.auto_awesome, size: 14, color: LearnUi.accent),
            ],
          ),
          const SizedBox(height: 16),
          _StreakCard(
            streakDays: stats?.currentStreakDays ?? 0,
            hit: hitDays,
            bestDays: stats?.bestStreakDays ?? 0,
            skillsInProgress: '$inProgress',
            pointsEarned: '${stats?.totalPoints ?? 0}',
          ),
        ],
      ),
    );
  }
}

/// An enlarged standalone copy of Home's compact streak tile
/// (`HomeProgressCard(kind: streak)`) — same visual language and rose
/// accent, sized to be the focal element of a full-width section rather
/// than a cramped 1-of-3 tile.
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streakDays,
    required this.hit,
    required this.bestDays,
    required this.skillsInProgress,
    required this.pointsEarned,
  });

  final int streakDays;
  final List<bool> hit;
  final int bestDays;
  final String skillsInProgress;
  final String pointsEarned;

  static const _color = Color(0xFF6AACDE);
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ui = LearnUi.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ui.card, _color.withValues(alpha: ui.isDark ? 0.22 : 0.12)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: _color, size: 24),
              ),
              const Spacer(),
              SizedBox(
                width: 64,
                child: _MiniStat(
                  icon: Icons.auto_stories_outlined,
                  value: skillsInProgress,
                  label: S.literal('Ongoing Skills'),
                  color: ui.textPrimary,
                  secondaryColor: ui.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: _MiniStat(
                  icon: Icons.star_outline_rounded,
                  value: pointsEarned,
                  label: S.literal('Points Earned'),
                  color: ui.textPrimary,
                  secondaryColor: ui.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${streakDays}d',
            style: TextStyle(
              fontFamily: 'Saira',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: ui.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            S.literal('Streak'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ui.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            S.literal("You're on fire!"),
            style: TextStyle(fontSize: 12, color: ui.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayCircle(done: hit[i], label: _labels[i], color: _color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: _color),
              const SizedBox(width: 4),
              Text(
                '${S.literal('Best')}: ${bestDays}d',
                style: TextStyle(
                    fontSize: 12, color: ui.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.done,
    required this.label,
    required this.color,
  });

  final bool done;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color.withValues(alpha: 0.9) : color.withValues(alpha: 0.14),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.6),
              ),
            ),
    );
  }
}

/// A compact icon+value+title stat — used in the streak card's header row.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.secondaryColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Saira',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _AchievementDef {
  const _AchievementDef({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
}

const _achievementDefs = [
  _AchievementDef(
    key: 'first_step',
    label: 'First Step',
    hint: 'Do anything in the app for the first time',
    icon: Icons.flag_rounded,
    color: HomeUi.accent,
  ),
  _AchievementDef(
    key: 'quick_learner',
    label: 'Quick Learner',
    hint: 'Complete your first skill topic',
    icon: Icons.bolt_rounded,
    color: HomeUi.earn,
  ),
  _AchievementDef(
    key: 'community_star',
    label: 'Community Star',
    hint: 'Join your first community',
    icon: Icons.star_rounded,
    color: HomeUi.grow,
  ),
  _AchievementDef(
    key: 'go_getter',
    label: 'Go-Getter',
    hint: 'Apply to a job or connect with a mentor',
    icon: Icons.rocket_launch_rounded,
    color: HomeUi.thrive,
  ),
  _AchievementDef(
    key: 'consistent',
    label: 'Consistent',
    hint: 'Reach a 3-day streak',
    icon: Icons.local_fire_department_rounded,
    color: HomeUi.learn,
  ),
];

/// Real, rule-based unlocks computed from actual data — no achievement is
/// ever marked earned unless the underlying action genuinely happened. A
/// brand-new user sees every badge locked.
final unlockedAchievementsProvider = Provider<List<String>>((ref) {
  final hasActivity = ref.watch(hasAnyActivityProvider).valueOrNull ?? false;
  final completedTopics = ref.watch(completedTopicsCountProvider).valueOrNull ?? 0;
  final communities = ref.watch(myGroupsProvider).valueOrNull?.length ?? 0;
  final applications = ref.watch(myApplicationsCountProvider).valueOrNull ?? 0;
  final mentorConnections = (ref.watch(conversationsProvider).valueOrNull ?? const [])
      .where((c) => c.type == 'mentor')
      .length;
  final bestStreak = ref.watch(userStatsProvider).valueOrNull?.bestStreakDays ?? 0;

  return [
    if (hasActivity) 'first_step',
    if (completedTopics >= 1) 'quick_learner',
    if (communities >= 1) 'community_star',
    if (applications >= 1 || mentorConnections >= 1) 'go_getter',
    if (bestStreak >= 3) 'consistent',
  ];
});

/// Exactly 5 badges per row (matching Home's dense icon-grid density),
/// any beyond 5 wrap to additional rows. Row uses top cross-alignment so
/// icons always line up regardless of whether a neighboring badge's title
/// wraps to a second line. Unearned badges show locked, not hidden — so a
/// new user can see what there is to work toward.
class _AchievementsGrid extends ConsumerWidget {
  const _AchievementsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedAchievementsProvider).toSet();

    const perRow = 5;
    final rows = <List<_AchievementDef>>[];
    for (var i = 0; i < _achievementDefs.length; i += perRow) {
      rows.add(_achievementDefs.sublist(i, (i + perRow).clamp(0, _achievementDefs.length)));
    }

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < perRow; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: i < rows[r].length
                      ? _BadgeTile(
                          def: rows[r][i],
                          unlocked: unlocked.contains(rows[r][i].key),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.def, required this.unlocked});

  final _AchievementDef def;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? def.color : HomeUi.of(context).textSecondary;
    return TapScale(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unlocked ? def.label : '${S.literal('Locked')}: ${def.hint}')),
      ),
      borderRadius: 99,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: unlocked ? 0.14 : 0.08),
                ),
                child: Icon(def.icon, color: color, size: 22),
              ),
              if (!unlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HomeUi.of(context).card,
                      border: Border.all(color: HomeUi.of(context).border),
                    ),
                    child: Icon(Icons.lock_outline, size: 11, color: HomeUi.of(context).textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            def.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: unlocked ? HomeUi.of(context).textPrimary : HomeUi.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Edit profile sheet ───────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({
    required this.name,
    this.role,
    this.location,
    this.about,
    this.avatarPath,
  });

  final String name;
  final String? role;
  final String? location;
  final String? about;
  final String? avatarPath;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.name);
  late final _aboutController = TextEditingController(text: widget.about ?? '');
  late final _locationController =
      TextEditingController(text: widget.location ?? '');
  late String? _selectedRole = widget.role;
  late String? _avatarPath = widget.avatarPath;
  bool _pickingImage = false;
  bool _saving = false;

  static const _roles = [
    'Entrepreneur',
    'Farmer',
    'Student',
    'Job Seeker',
    'Community Leader',
    'Artisan / Creator',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final path = await _pickAndSaveProfilePhoto();
    if (!mounted) return;
    setState(() {
      _pickingImage = false;
      if (path != null) _avatarPath = path;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(userDaoProvider).saveUser(
          name: _nameController.text.trim(),
          role: _selectedRole,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          about: _aboutController.text.trim(),
          avatarPath: _avatarPath,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                        color: ui.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: ui.textPrimary, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        S.literal('Edit Profile'),
                        style: TextStyle(
                            fontFamily: 'Saira',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ui.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: _pickingImage ? null : _pickImage,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarPath == null
                              ? HomeUi.accent.withValues(alpha: 0.12)
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickingImage
                            ? const Center(
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : _avatarPath != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(File(_avatarPath!),
                                          fit: BoxFit.cover),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _avatarPath = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.add_a_photo_outlined,
                                    color: HomeUi.accent, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        InputDecoration(hintText: S.literal('Your name')),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? S.literal('Enter your name')
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _aboutController,
                    maxLines: 3,
                    decoration: InputDecoration(
                        hintText:
                            S.literal('Tell others a little about yourself')),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    S.literal('I am a'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ui.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _roles.map((r) {
                      final isSelected = _selectedRole == r;
                      return ChoiceChip(
                        label: Text(S.literal(r)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedRole = r),
                        selectedColor: HomeUi.accent.withValues(alpha: 0.16),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? HomeUi.accent
                              : ui.textSecondary,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? HomeUi.accent
                              : ui.border,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: S.literal('e.g. Kampala, Mukono, Mbale'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: TapScale(
                      borderRadius: HomeUi.radiusBtn,
                      onTap: _saving ? () {} : _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [HomeUi.accent, HomeUi.accentDeep],
                          ),
                          borderRadius:
                              BorderRadius.circular(HomeUi.radiusBtn),
                          boxShadow: [
                            BoxShadow(
                              color: HomeUi.accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                S.literal('Save Changes'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
