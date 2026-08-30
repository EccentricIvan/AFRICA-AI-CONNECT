import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../shared/widgets/community/community_group_card.dart';
import '../../../shared/widgets/community/community_header_bar.dart';
import '../../../shared/widgets/community/community_hero_card.dart';
import '../../../shared/widgets/community/community_ui.dart';
import '../../../shared/widgets/messaging/chat_room_screen.dart';

/// Copies a user-picked image into the app's own persistent documents
/// directory, mirroring Marketplace's `_pickAndSaveImage` — the OS
/// picker's temp/cache path isn't guaranteed to survive.
Future<String?> _pickAndSaveGroupImage() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) return null;

  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'community_group_photos'));
  if (!await photosDir.exists()) await photosDir.create(recursive: true);

  final destPath = p.join(
    photosDir.path,
    '${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedPath)}',
  );
  await File(pickedPath).copy(destPath);
  return destPath;
}

/// Category taxonomy for community groups — a fixed UI mapping (label →
/// icon/color keys), same convention as Marketplace's category metadata.
/// Not a data model: categories don't need their own table.
const _categoryOptions = [
  ('Business', 'trending_up', 'business'),
  ('Digital Skills', 'computer', 'digital'),
  ('Agriculture', 'agriculture', 'agriculture'),
  ('Family & Support', 'child_care', 'family'),
  ('Fashion & Crafts', 'checkroom', 'fashion'),
  ('Finance', 'savings', 'finance'),
];

IconData iconForGroupKey(String key) {
  switch (key) {
    case 'trending_up':
      return Icons.trending_up;
    case 'computer':
      return Icons.computer;
    case 'agriculture':
      return Icons.agriculture;
    case 'child_care':
      return Icons.child_care;
    case 'checkroom':
      return Icons.checkroom;
    case 'savings':
      return Icons.savings;
    case 'diversity':
      return Icons.diversity_1_rounded;
    default:
      return Icons.groups_rounded;
  }
}

Color colorForGroupKey(String key) {
  switch (key) {
    case 'business':
      return const Color(0xFF2E8B8B);
    case 'digital':
      return const Color(0xFF7C5CBF);
    case 'agriculture':
      return const Color(0xFF5E8C4A);
    case 'family':
      return const Color(0xFFB4436C);
    case 'fashion':
      return const Color(0xFFD4A24E);
    case 'finance':
      return const Color(0xFF5B8AA8);
    case 'mentorship':
      return const Color(0xFFB4436C);
    default:
      return CommunityUi.accent;
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    setState(() => _tab = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openCreateGroup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CommunityUi.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateGroupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final groupsAsync = ref.watch(groupsProvider);
        final groupCount = groupsAsync.valueOrNull?.length ?? 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: AppColors.pageDecoration(context),
            child: SafeArea(
              child: Column(
                children: [
                  CommunityHeaderBar(
                    title: S.literal('Community'),
                    onBack: () => context.go('/'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _FadeSlideIn(
                      child: CommunityHeroCard(
                        title: S.literal('Stronger together'),
                        body: S.literal('Connect. Learn. Grow.'),
                        membershipLine: groupCount == 0
                            ? S.literal('Be the first to start a community')
                            : '$groupCount ${S.literal('communities to join')}',
                        avatarColors: const [
                          CommunityUi.accent,
                          CommunityUi.accentDeep,
                          Color(0xFF5BB8E8),
                        ],
                        ctaLabel: S.literal('Create a Community'),
                        onCta: _openCreateGroup,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CommunityTabBar(
                      selected: _tab,
                      onChanged: _selectTab,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _tab = i),
                      children: const [
                        _ChatsTab(),
                        _DiscoverTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: c),
      ),
      child: child,
    );
  }
}

// ──────────────────────────────── Tabs ────────────────────────────────

class _CommunityTabBar extends StatelessWidget {
  const _CommunityTabBar({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final labels = [
      S.literal('Chats'),
      S.literal('Discover'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ui.iconWell,
        borderRadius: BorderRadius.circular(CommunityUi.radiusChip + 4),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _TabSegment(
                label: labels[i],
                active: selected == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return TapScale(
      borderRadius: CommunityUi.radiusChip,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? ui.card : Colors.transparent,
          borderRadius: BorderRadius.circular(CommunityUi.radiusChip),
          boxShadow: active ? ui.pillShadow : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? CommunityUi.accent : ui.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared shape for each tab: a title, a search field right under it,
/// then the scrollable list.
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.title,
    required this.searchHint,
    required this.onSearchChanged,
    required this.child,
    this.trailing,
  });

  final String title;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Saira',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ui.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(hint: searchHint, onChanged: onSearchChanged),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _ChatsTab extends ConsumerStatefulWidget {
  const _ChatsTab();

  @override
  ConsumerState<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<_ChatsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final q = _query.trim().toLowerCase();

    return _TabScaffold(
      title: S.literal('Chats'),
      searchHint: S.literal('Search your communities'),
      onSearchChanged: (v) => setState(() => _query = v),
      child: myGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load your communities.'))),
        data: (groups) {
          final list = q.isEmpty
              ? groups
              : groups.where((g) => g.name.toLowerCase().contains(q)).toList();
          if (list.isEmpty) {
            return Center(
              child: Text(
                groups.isEmpty
                    ? S.literal('Join a community to start chatting')
                    : S.literal('No conversations found'),
                style: TextStyle(fontSize: 13, color: ui.textSecondary),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: list.map((g) => _ChatRow(group: g)).toList(),
          );
        },
      ),
    );
  }
}

class _ChatRow extends ConsumerWidget {
  const _ChatRow({required this.group});
  final Group group;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final conversationId = await ref.read(messagingDaoProvider).getOrCreateConversation(
          type: 'group',
          subjectId: group.id,
          title: group.name,
        );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorForGroupKey(group.colorKey);
    return CommunityGroupCard(
      onTap: () => _open(context, ref),
      leading: CommunityAvatar(color: color, initial: group.name[0], imagePath: group.imagePath),
      title: group.name,
      subtitle: _CategoryTag(color: color, label: group.category),
      trailing: Icon(Icons.chevron_right_rounded, color: CommunityUi.of(context).textSecondary),
    );
  }
}

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  String _query = '';
  final Set<String> _categories = {};

  bool get _hasActiveFilters => _categories.isNotEmpty;

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: CommunityUi.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(initialCategories: _categories),
    );
    if (result != null && mounted) {
      setState(() {
        _categories
          ..clear()
          ..addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final groupsAsync = ref.watch(groupsProvider);
    final q = _query.trim().toLowerCase();

    return _TabScaffold(
      title: S.literal('Communities'),
      searchHint: S.literal('Search groups to join'),
      onSearchChanged: (v) => setState(() => _query = v),
      trailing: TapScale(
        borderRadius: 25,
        onTap: _openFilter,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _hasActiveFilters
                ? CommunityUi.accent.withValues(alpha: 0.14)
                : ui.card,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.tune_rounded,
              size: 20,
              color: _hasActiveFilters
                  ? CommunityUi.accent
                  : ui.textSecondary),
        ),
      ),
      child: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(S.literal('Could not load communities.'))),
        data: (groups) {
          final list = groups.where((g) {
            final matchesQuery = q.isEmpty || g.name.toLowerCase().contains(q);
            final matchesCategory =
                _categories.isEmpty || _categories.contains(g.category);
            return matchesQuery && matchesCategory;
          }).toList();
          if (list.isEmpty) {
            return Center(
              child: Text(S.literal('No groups found'),
                  style: TextStyle(fontSize: 13, color: ui.textSecondary)),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: list.map((g) => _DiscoverGroupRow(group: g)).toList(),
          );
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initialCategories});
  final Set<String> initialCategories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _categories = {...widget.initialCategories};

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Padding(
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
                color: ui.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            S.literal('Filter Communities'),
            style: TextStyle(
                fontFamily: 'Saira',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ui.textPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            S.literal('Category'),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: ui.textPrimary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _categoryOptions.map((c) {
              final label = c.$1;
              final isSelected = _categories.contains(label);
              return ChoiceChip(
                label: Text(S.literal(label)),
                selected: isSelected,
                onSelected: (_) => setState(
                    () => isSelected ? _categories.remove(label) : _categories.add(label)),
                selectedColor: CommunityUi.accent.withValues(alpha: 0.16),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? CommunityUi.accent : ui.textSecondary,
                ),
                side: BorderSide(color: isSelected ? CommunityUi.accent : ui.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TapScale(
              borderRadius: CommunityUi.radiusBtn,
              onTap: () => Navigator.of(context).pop(_categories),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CommunityUi.accent, CommunityUi.accentDeep],
                  ),
                  borderRadius: BorderRadius.circular(CommunityUi.radiusBtn),
                ),
                child: Text(S.literal('Apply'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.onChanged});
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: ui.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: ui.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, size: 21, color: ui.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _MemberAvatars extends ConsumerWidget {
  const _MemberAvatars({required this.color, required this.groupId});
  final Color color;
  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = CommunityUi.of(context);
    final members = ref.watch(groupMembersProvider(groupId)).valueOrNull ?? const [];
    const size = 22.0;
    const overlap = size * 0.62;
    final dots = members.isEmpty ? 1 : members.length.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: overlap * (dots - 1) + size,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < dots; i++)
                Positioned(
                  left: i * overlap,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(color, Colors.white, i * 0.22),
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${members.length} ${S.literal('members')}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ui.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────── Join button ───────────────────────────

class _JoinButton extends ConsumerStatefulWidget {
  const _JoinButton({required this.color, required this.group});
  final Color color;
  final Group group;

  @override
  ConsumerState<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<_JoinButton> {
  bool _busy = false;

  Future<void> _toggle(bool isMember) async {
    setState(() => _busy = true);
    if (isMember) {
      await ref.read(groupsDaoProvider).leaveGroup(widget.group.id);
    } else {
      final user = await ref.read(currentUserProvider.future);
      await ref.read(groupsDaoProvider).joinGroup(
            groupId: widget.group.id,
            memberName: user?.name ?? S.literal('Me'),
          );
      await ref.read(messagingDaoProvider).getOrCreateConversation(
            type: 'group',
            subjectId: widget.group.id,
            title: widget.group.name,
          );
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CommunityUi.of(context).textPrimary,
        content: Text(
          isMember
              ? '${S.literal('Left')} ${widget.group.name}'
              : '${S.literal('Joined')} ${widget.group.name}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final color = widget.color;
    final isMember = ref.watch(isGroupMemberProvider(widget.group.id)).valueOrNull ?? false;
    return TapScale(
      borderRadius: 20,
      onTap: () {
        if (!_busy) _toggle(isMember);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isMember
              ? null
              : LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.15)!],
                ),
          color: isMember ? ui.iconWell : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isMember
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Row(
                  key: ValueKey(isMember),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isMember ? Icons.check_rounded : Icons.add_rounded,
                        size: 14, color: isMember ? color : Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      isMember ? S.literal('Joined') : S.literal('Join'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isMember ? color : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────── Create Group form ───────────────────────

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  String? _imagePath;
  bool _pickingImage = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final path = await _pickAndSaveGroupImage();
    if (!mounted) return;
    setState(() {
      _pickingImage = false;
      if (path != null) _imagePath = path;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.literal('Please choose a category'))),
      );
      return;
    }
    setState(() => _submitting = true);
    final name = _nameController.text.trim();
    final meta = _categoryOptions.firstWhere((c) => c.$1 == _selectedCategory);

    final groupId = await ref.read(groupsDaoProvider).createGroup(
          name: name,
          category: meta.$1,
          iconKey: meta.$2,
          colorKey: meta.$3,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          imagePath: _imagePath,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
        );
    final user = await ref.read(currentUserProvider.future);
    await ref.read(groupsDaoProvider).joinGroup(
          groupId: groupId,
          memberName: user?.name ?? S.literal('Me'),
        );
    await ref.read(messagingDaoProvider).getOrCreateConversation(
          type: 'group',
          subjectId: groupId,
          title: name,
        );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CommunityUi.of(context).textPrimary,
        content: Text(
          '${S.literal('Community created')}: $name',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
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
                      color: ui.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  S.literal('Create a Community'),
                  style: TextStyle(
                      fontFamily: 'Saira',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary),
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: _pickingImage ? null : _pickImage,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _imagePath == null ? ui.iconWell : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickingImage
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _imagePath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imagePath = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.add_a_photo_outlined,
                                  color: CommunityUi.accent, size: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: S.literal('Group name')),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? S.literal('Enter a group name') : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(hintText: S.literal('Location (optional)')),
                ),
                const SizedBox(height: 14),
                Text(
                  S.literal('Category'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ui.textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryOptions.map((c) {
                    final label = c.$1;
                    final isSelected = _selectedCategory == label;
                    return ChoiceChip(
                      label: Text(S.literal(label)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = label),
                      selectedColor: CommunityUi.accent.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? CommunityUi.accent : ui.textSecondary,
                      ),
                      side: BorderSide(color: isSelected ? CommunityUi.accent : ui.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: S.literal('What is this group about?')),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: TapScale(
                    borderRadius: CommunityUi.radiusBtn,
                    onTap: () {
                      if (!_submitting) _submit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [CommunityUi.accent, CommunityUi.accentDeep],
                        ),
                        borderRadius: BorderRadius.circular(CommunityUi.radiusBtn),
                        boxShadow: [
                          BoxShadow(
                            color: CommunityUi.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              S.literal('Create Community'),
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                    ),
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

// ─────────────────────────── Group preview popup ───────────────────────

Future<void> _showGroupPreview(BuildContext context, Group group) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.literal('Dismiss'),
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, anim2) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _GroupPreviewCard(group: group),
      ),
    ),
    transitionBuilder: (ctx, animation, __, child) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6 * animation.value, sigmaY: 6 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    ),
  );
}

class _GroupPreviewCard extends StatelessWidget {
  const _GroupPreviewCard({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final g = group;
    final color = colorForGroupKey(g.colorKey);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(CommunityUi.radiusCard),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  height: 92,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.15)!],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Icon(iconForGroupKey(g.iconKey), color: color, size: 28),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.literal(g.name),
                    style: TextStyle(
                        fontFamily: 'Saira', fontSize: 16, fontWeight: FontWeight.w700, color: ui.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryTag(color: color, label: g.category),
                      if (g.location != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_rounded, size: 13, color: color),
                        const SizedBox(width: 2),
                        Text(
                          S.literal(g.location!),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(color: color, groupId: g.id),
                  const SizedBox(height: 12),
                  Text(
                    g.description ??
                        S.literal(
                          'A place for women in this community to share opportunities, ask questions, and support one another.',
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: ui.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _JoinButton(color: color, group: g),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => _GroupDetailPage(group: g)),
                          );
                        },
                        child: Text(S.literal('View details')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Discover / groups ──────────────────────

class _DiscoverGroupRow extends StatelessWidget {
  const _DiscoverGroupRow({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    final color = colorForGroupKey(g.colorKey);
    return CommunityGroupCard(
      onTap: () => _showGroupPreview(context, g),
      leading: CommunityAvatar(color: color, initial: g.name[0], imagePath: g.imagePath),
      title: S.literal(g.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CategoryTag(color: color, label: g.category),
          const SizedBox(height: 5),
          _MemberAvatars(color: color, groupId: g.id),
        ],
      ),
      trailing: _JoinButton(color: color, group: g),
    );
  }
}

/// The group's detail view — shown from the Discover preview or from a
/// chat room's header.
class _GroupDetailPage extends ConsumerWidget {
  const _GroupDetailPage({required this.group});
  final Group group;

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final conversationId = await ref.read(messagingDaoProvider).getOrCreateConversation(
          type: 'group',
          subjectId: group.id,
          title: group.name,
        );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = CommunityUi.of(context);
    final g = group;
    final color = colorForGroupKey(g.colorKey);
    final isMember = ref.watch(isGroupMemberProvider(g.id)).valueOrNull ?? false;
    final membersAsync = ref.watch(groupMembersProvider(g.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.pageDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              CommunitySubPageHeaderBar(
                onBack: () => Navigator.of(context).pop(),
                title: S.literal(g.name),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(CommunityUi.radiusHero),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.55)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Icon(iconForGroupKey(g.iconKey), color: color, size: 34),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    S.literal(g.name),
                    style: TextStyle(
                        fontFamily: 'Saira', fontSize: 19, fontWeight: FontWeight.w700, color: ui.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryTag(color: color, label: g.category),
                      if (g.location != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_rounded, size: 13, color: color),
                        const SizedBox(width: 2),
                        Text(
                          S.literal(g.location!),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(color: color, groupId: g.id),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isMember)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: color, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                S.literal("You're a member"),
                                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        _JoinButton(color: color, group: g),
                      const SizedBox(width: 10),
                      if (isMember)
                        TapScale(
                          borderRadius: 20,
                          onTap: () => _openChat(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.forum_outlined, size: 15, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  S.literal('Open Chat'),
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.literal('About'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ui.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    g.description ??
                        S.literal(
                          "A place for women in this community to share opportunities, ask questions, and support one another's growth.",
                        ),
                    style: TextStyle(fontSize: 13, color: ui.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  membersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (members) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${S.literal('Members')} (${members.length})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ui.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        if (members.isEmpty)
                          Text(
                            S.literal('No members yet — be the first to join.'),
                            style: TextStyle(fontSize: 12, color: ui.textSecondary),
                          )
                        else
                          ...members.map((m) => _MemberListRow(color: color, member: m)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MemberListRow extends StatelessWidget {
  const _MemberListRow({required this.color, required this.member});
  final Color color;
  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CommunityAvatar(color: color, initial: member.memberName[0], size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.isMe ? '${member.memberName} (${S.literal('You')})' : member.memberName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ui.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The community's category (Business, Agriculture, ...) shown as a tag
/// wherever a group's details are shown.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.literal(label),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
