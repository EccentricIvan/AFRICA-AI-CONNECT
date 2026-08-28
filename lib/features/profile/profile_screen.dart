import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/l10n/app_strings.dart';
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
      backgroundColor: ui.pageBg,
      body: Stack(
        children: [
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
          colors: [HomeUi.accent, HomeUi.thrive],
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
              _GlassCircleBtn(Icons.arrow_back_rounded, onBack),
              const Spacer(),
              _GlassCircleBtn(Icons.edit_outlined, onEdit),
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

class _GlassCircleBtn extends StatelessWidget {
  const _GlassCircleBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
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

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    final stats = [
      (S.literal('Completed Courses'), '6', Icons.menu_book_outlined,
          HomeUi.learn),
      (S.literal('Communities Joined'), '3', Icons.groups_outlined, HomeUi.grow),
      (S.literal('Badges Earned'), '5', Icons.emoji_events_outlined,
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
class _ProfileProgressBanner extends StatelessWidget {
  const _ProfileProgressBanner();

  @override
  Widget build(BuildContext context) {
    // Mon..Sun — mock week, matching the "5" badge/streak-day mock numbers
    // used elsewhere on this screen.
    const hitDays = [true, true, true, true, true, false, false];
    final ui = LearnUi.of(context);

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
          const _StreakCard(
            streakDays: 7,
            hit: hitDays,
            bestDays: 12,
            coursesInProgress: '2',
            pointsEarned: '450',
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
    required this.coursesInProgress,
    required this.pointsEarned,
  });

  final int streakDays;
  final List<bool> hit;
  final int bestDays;
  final String coursesInProgress;
  final String pointsEarned;

  static const _color = Color(0xFFE89A9A);
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
                  value: coursesInProgress,
                  label: S.literal('Ongoing Courses'),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.earnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role ?? S.literal('Member'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.earnColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location ?? S.literal('Location not set'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
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
  const _BadgeTile({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {},
      borderRadius: 99,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: HomeUi.of(context).textPrimary,
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
  Widget build(BuildContext context) {
    final stats = [
      const _Stat('Courses', '3', AppColors.learnColor),
      const _Stat('Points', '450', AppColors.earnColor),
      const _Stat('Streak', '7 days', AppColors.healthColor),
      const _Stat('Badges', '5', AppColors.growColor),
    ];

    return Row(
      children:
          stats.map((s) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.color.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      s.label == 'Streak' ? '7 ${S.literal('days')}' : s.value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: s.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.literal(s.label),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
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

class _ProgressCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Digital Skills', 0.65, AppColors.skillsColor),
      ('Financial Literacy', 0.40, AppColors.financeColor),
      ('Entrepreneurship', 0.25, AppColors.earnColor),
    ];

    return Column(
      children:
          items.map((p) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            S.literal(p.$1),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${(p.$2 * 100).round()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.$3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: p.$2,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(p.$3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  static const _badges = [
    ('First Step', Icons.flag, AppColors.primary),
    ('Quick Learner', Icons.bolt, AppColors.earnColor),
    ('Community Star', Icons.star, AppColors.communityColor),
    ('Entrepreneur', Icons.rocket_launch, AppColors.marketplaceColor),
    ('Consistent', Icons.local_fire_department, AppColors.healthColor),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          _badges.map((b) {
            return Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: b.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: b.$3.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(b.$2, color: b.$3, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    S.literal(b.$1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
