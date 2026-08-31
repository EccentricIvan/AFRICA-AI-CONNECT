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
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/glass/glass_circle_btn.dart';
import '../../../shared/widgets/tap_scale.dart';
import '../../../shared/widgets/community/community_group_card.dart';
import '../../../shared/widgets/community/community_header_bar.dart';
import '../../../shared/widgets/community/community_hero_card.dart';
import '../../../shared/widgets/community/community_ui.dart';

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

/// The mock data every tab and the search overlay reads from — pulled
/// out of any one screen/page class now that Discover/My Community/
/// Feed are tabs on one screen rather than separate pushed pages.
class _CommunityData {
  _CommunityData._();

  static const groups = [
    _Group('Kampala Women Entrepreneurs', 124, Icons.trending_up,
        Color(0xFF2E8B8B), 'Business', 'Kampala'),
    _Group('Digital Skills Network', 89, Icons.computer, Color(0xFF7C5CBF),
        'Digital Skills', 'Kampala'),
    _Group('Farmers United', 256, Icons.agriculture, Color(0xFF5E8C4A),
        'Agriculture', 'Gulu'),
    _Group('Young Mothers Support', 67, Icons.child_care, Color(0xFFB4436C),
        'Family & Support', 'Mbale'),
    _Group('Tailors & Textile Circle', 52, Icons.checkroom, Color(0xFFD4A24E),
        'Fashion & Crafts', 'Jinja'),
    _Group('Savings Circle Kampala', 143, Icons.savings, Color(0xFF5B8AA8),
        'Finance', 'Kampala'),
  ];

  static const conversations = [
    _Conversation(
      _Group('Kampala Women Entrepreneurs', 124, Icons.trending_up,
          Color(0xFF2E8B8B), 'Business', 'Kampala'),
      'Grace',
      'Anyone free for the Saturday market meet-up?',
      '12m',
      unread: 3,
      senderColor: Color(0xFFD4A24E),
    ),
    _Conversation(
      _Group('Digital Skills Network', 89, Icons.computer, Color(0xFF7C5CBF),
          'Digital Skills', 'Kampala'),
      'Amina',
      'Just shared the new tutorial link!',
      '2h',
      unread: 2,
      senderColor: Color(0xFFB4436C),
    ),
    _Conversation(
      _Group('Farmers United', 256, Icons.agriculture, Color(0xFF5E8C4A),
          'Agriculture', 'Gulu'),
      'You',
      'Thanks everyone, see you at the training.',
      '1d',
      unread: 0,
      senderColor: CommunityUi.accent,
    ),
  ];

  static int get totalUnread =>
      conversations.fold(0, (sum, c) => sum + c.unread);
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
    final totalMembers =
        _CommunityData.groups.fold<int>(0, (sum, g) => sum + g.members);

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
                  membershipLine:
                      '${S.literal('Join')} $totalMembers ${S.literal('women across')} ${_CommunityData.groups.length} ${S.literal('communities')}',
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
                unreadBadge: _CommunityData.totalUnread,
                onChanged: _selectTab,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              // A real sliding transition between tabs — tapping a segment
              // animates the page; swiping works too, for free.
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

/// Chats (default) / Feed / Discover — a pill segmented control
/// switching between three full-height tabs instead of three stacked
/// preview sections.
class _CommunityTabBar extends StatelessWidget {
  const _CommunityTabBar({
    required this.selected,
    required this.onChanged,
    required this.unreadBadge,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final int unreadBadge;

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
                badge: i == 0 && unreadBadge > 0 ? unreadBadge : null,
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
    this.badge,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

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
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: CommunityUi.unread,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? _CommunityData.conversations
        : _CommunityData.conversations
            .where((c) =>
                c.group.name.toLowerCase().contains(q) ||
                c.lastMessage.toLowerCase().contains(q))
            .toList();

    return _TabScaffold(
      title: S.literal('Chats'),
      searchHint: S.literal('Search your communities'),
      onSearchChanged: (v) => setState(() => _query = v),
      child: list.isEmpty
          ? Center(
              child: Text(S.literal('No conversations found'),
                  style: TextStyle(
                      fontSize: 13, color: ui.textSecondary)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children:
                  list.map((c) => _ConversationRow(conversation: c)).toList(),
            ),
    );
  }
}

/// The "Discover" tab bar segment opens this — titled "Communities"
/// inline, since that's what's actually being browsed here.
class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  String _query = '';
  final Set<String> _categories = {};
  final Set<String> _locations = {};

  bool get _hasActiveFilters => _categories.isNotEmpty || _locations.isNotEmpty;

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<(Set<String>, Set<String>)>(
      context: context,
      backgroundColor: CommunityUi.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        initialCategories: _categories,
        initialLocations: _locations,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _categories
          ..clear()
          ..addAll(result.$1);
        _locations
          ..clear()
          ..addAll(result.$2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final q = _query.trim().toLowerCase();
    final list = _CommunityData.groups.where((g) {
      final matchesQuery = q.isEmpty || g.name.toLowerCase().contains(q);
      final matchesCategory =
          _categories.isEmpty || _categories.contains(g.category);
      final matchesLocation =
          _locations.isEmpty || _locations.contains(g.location);
      return matchesQuery && matchesCategory && matchesLocation;
    }).toList();

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
      child: list.isEmpty
          ? Center(
              child: Text(S.literal('No groups found'),
                  style: TextStyle(
                      fontSize: 13, color: ui.textSecondary)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: list.map((g) => _DiscoverGroupRow(group: g)).toList(),
            ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initialCategories, required this.initialLocations});
  final Set<String> initialCategories;
  final Set<String> initialLocations;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _categories = {...widget.initialCategories};
  late final Set<String> _locations = {...widget.initialLocations};

  static const _categoryOptions = [
    'Business',
    'Digital Skills',
    'Agriculture',
    'Family & Support',
    'Fashion & Crafts',
    'Finance',
  ];

  static const _locationOptions = [
    'Kampala',
    'Gulu',
    'Mbale',
    'Jinja',
  ];

  Widget _chipRow(
    String label,
    List<String> options,
    Set<String> selected,
  ) {
    final ui = CommunityUi.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.literal(label),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ui.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: options.map((c) {
            final isSelected = selected.contains(c);
            return ChoiceChip(
              label: Text(S.literal(c)),
              selected: isSelected,
              onSelected: (_) => setState(
                  () => isSelected ? selected.remove(c) : selected.add(c)),
              selectedColor: CommunityUi.accent.withValues(alpha: 0.16),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? CommunityUi.accent : ui.textSecondary,
              ),
              side: BorderSide(
                color: isSelected ? CommunityUi.accent : ui.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

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
          _chipRow('Category', _categoryOptions, _categories),
          const SizedBox(height: 18),
          _chipRow('Location', _locationOptions, _locations),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TapScale(
              borderRadius: CommunityUi.radiusBtn,
              onTap: () =>
                  Navigator.of(context).pop((_categories, _locations)),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
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
    // A true pill (radius = height / 2), generous icon padding — matching
    // the reference search bar's proportions, just in this app's light
    // "Markenzy" palette instead of a dark glass style. No filter icon.
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
          prefixIcon: Icon(Icons.search_rounded,
              size: 21, color: ui.textSecondary),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.color, required this.count});
  final Color color;
  final String count;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    const size = 22.0;
    const overlap = size * 0.62;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: overlap * 2 + size,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
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
          count,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ui.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Join button ───────────────────────────

class _JoinButton extends StatefulWidget {
  const _JoinButton({
    required this.color,
    required this.groupName,
  });
  final Color color;
  final String groupName;

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _joined = false;

  void _toggle() {
    setState(() => _joined = !_joined);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: CommunityUi.of(context).textPrimary,
        content: Text(
          _joined
              ? '${S.literal('Joined')} ${widget.groupName}'
              : '${S.literal('Left')} ${widget.groupName}',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final color = widget.color;
    return TapScale(
      borderRadius: 20,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _joined
              ? null
              : LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.15)!],
                ),
          color: _joined ? ui.iconWell : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _joined
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Row(
            key: ValueKey(_joined),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_joined ? Icons.check_rounded : Icons.add_rounded,
                  size: 14, color: _joined ? color : Colors.white),
              const SizedBox(width: 4),
              Text(
                _joined ? S.literal('Joined') : S.literal('Join'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _joined ? color : Colors.white,
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

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  String? _imagePath;
  bool _pickingImage = false;

  static const _categories = [
    'Business',
    'Digital Skills',
    'Agriculture',
    'Family & Support',
    'Fashion & Crafts',
    'Finance',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.literal('Please choose a category'))),
      );
      return;
    }
    final name = _nameController.text.trim();
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
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : _imagePath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _imagePath = null),
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
                                  color: CommunityUi.accent, size: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: S.literal('Group name')),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? S.literal('Enter a group name')
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  S.literal('Category'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ui.textPrimary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final isSelected = _selectedCategory == c;
                    return ChoiceChip(
                      label: Text(S.literal(c)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = c),
                      selectedColor: CommunityUi.accent.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? CommunityUi.accent
                            : ui.textSecondary,
                      ),
                      side: BorderSide(
                        color:
                            isSelected ? CommunityUi.accent : ui.border,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                      hintText: S.literal('What is this group about?')),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: TapScale(
                    borderRadius: CommunityUi.radiusBtn,
                    onTap: _submit,
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
                      child: Text(
                        S.literal('Create Community'),
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
    );
  }
}

// ─────────────────────────── Group preview popup ───────────────────────

Future<void> _showGroupPreview(BuildContext context, _Group group) {
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
      filter: ImageFilter.blur(
          sigmaX: 6 * animation.value, sigmaY: 6 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    ),
  );
}

class _GroupPreviewCard extends StatelessWidget {
  const _GroupPreviewCard({required this.group});
  final _Group group;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final g = group;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(CommunityUi.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
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
                      colors: [g.color, Color.lerp(g.color, Colors.black, 0.15)!],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: g.color, width: 3),
                    ),
                    child: Icon(g.icon, color: g.color, size: 28),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 22),
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
                      fontFamily: 'Saira',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryTag(color: g.color, label: g.category),
                      const SizedBox(width: 6),
                      Icon(Icons.location_on_rounded, size: 13, color: g.color),
                      const SizedBox(width: 2),
                      Text(
                        S.literal(g.location),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: g.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(color: g.color, count: '${g.memberCount} members'),
                  const SizedBox(height: 12),
                  Text(
                    S.literal(
                      'A place for women in this community to share opportunities, ask questions, and support one another.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ui.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _JoinButton(color: g.color, groupName: g.name),
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
  final _Group group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    return CommunityGroupCard(
      onTap: () => _showGroupPreview(context, g),
      leading: CommunityAvatar(color: g.color, initial: g.name[0]),
      title: S.literal(g.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CategoryTag(color: g.color, label: g.category),
          const SizedBox(height: 5),
          _MemberAvatars(color: g.color, count: '${g.memberCount} members'),
        ],
      ),
      trailing: _JoinButton(color: g.color, groupName: g.name),
    );
  }
}

class _Group {
  const _Group(this.name, this.members, this.icon, this.color, this.category,
      this.location);
  final String name;
  final int members;
  final IconData icon;
  final Color color;
  final String category;
  final String location;

  String get memberCount => '$members';
}

class _Member {
  const _Member(this.name, this.roles, {this.isAdmin = false});
  final String name;
  final List<String> roles;
  final bool isAdmin;
}

/// The "already a member" view — reached only from a group's chat
/// header, so membership is a fact, not a decision: no Join button,
/// just a status.
class _GroupDetailPage extends StatelessWidget {
  const _GroupDetailPage({required this.group});
  final _Group group;

  static const _mockMembers = [
    _Member('Sarah M.', ['Entrepreneur', 'Mentor', 'Community Leader'],
        isAdmin: true),
    _Member('Grace K.', ['Trader', 'Entrepreneur']),
    _Member('Amina', ['Student', 'Volunteer']),
    _Member('Peace N.', ['Mentor', 'Entrepreneur', 'Trader']),
    _Member('Joyce O.', ['Volunteer', 'Student']),
  ];

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final g = group;
    final creator = _mockMembers.first;
    return Scaffold(
      backgroundColor: ui.pageBg,
      body: SafeArea(
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
                        colors: [
                          g.color.withValues(alpha: 0.85),
                          g.color.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: g.color, width: 3),
                      ),
                      child: Icon(g.icon, color: g.color, size: 34),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    S.literal(g.name),
                    style: TextStyle(
                      fontFamily: 'Saira',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CategoryTag(color: g.color, label: g.category),
                      const SizedBox(width: 6),
                      Icon(Icons.location_on_rounded, size: 13, color: g.color),
                      const SizedBox(width: 2),
                      Text(
                        S.literal(g.location),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: g.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(color: g.color, count: '${g.memberCount} members'),
                  const SizedBox(height: 4),
                  Text(
                    '${S.literal('Created by')} ${creator.name}',
                    style: TextStyle(
                        fontSize: 12, color: ui.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: g.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: g.color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          S.literal("You're a member"),
                          style: TextStyle(
                            color: g.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.literal('About'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.literal(
                      'A place for women in this community to share opportunities, ask questions, and support one another\'s growth.',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: ui.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${S.literal('Members')} (${g.memberCount})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._mockMembers.map((m) => _MemberListRow(color: g.color, member: m)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberListRow extends StatelessWidget {
  const _MemberListRow({required this.color, required this.member});
  final Color color;
  final _Member member;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final m = member;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAvatar(color: color, initial: m.name[0], size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(m.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ui.textPrimary)),
                    if (m.isAdmin) ...[
                      const SizedBox(width: 6),
                      const _AdminBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: m.roles.map((r) => _RoleChip(label: r)).toList(),
                ),
              ],
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A24E).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.literal('Admin'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB48A2E),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ui.iconWell,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        S.literal(label),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ui.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────── Chatroom ────────────────────────────

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});
  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final c = conversation;
    return CommunityGroupCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _ChatRoomPage(conversation: c)),
      ),
      // The last sender's own avatar, not the group's — matches how a
      // real chat list shows who most recently spoke.
      leading: CommunityAvatar(color: c.senderColor, initial: c.lastSender[0]),
      title: c.group.name,
      subtitle: Text(
        '${c.lastSender}: ${c.lastMessage}',
        style: TextStyle(
          fontSize: 12,
          color: c.unread > 0 ? ui.textPrimary : ui.textSecondary,
          fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.literal(c.time),
            style: TextStyle(fontSize: 11, color: ui.textSecondary),
          ),
          const SizedBox(height: 6),
          if (c.unread > 0)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CommunityUi.unread,
              ),
              child: Text(
                '${c.unread}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Conversation {
  const _Conversation(
      this.group, this.lastSender, this.lastMessage, this.time,
      {this.unread = 0, required this.senderColor});
  final _Group group;
  final String lastSender;
  final String lastMessage;
  final String time;
  final int unread;
  final Color senderColor;
}

class _ChatRoomPage extends ConsumerStatefulWidget {
  const _ChatRoomPage({required this.conversation});
  final _Conversation conversation;

  @override
  ConsumerState<_ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<_ChatRoomPage> {
  late final List<(String sender, String text, bool isMe)> _messages;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final c = widget.conversation;
    _messages = [
      (c.lastSender, "Hey everyone, hope you're all doing well this week!",
          c.lastSender == 'You'),
      ('You', 'Doing great, thanks for asking!', true),
      (c.lastSender, c.lastMessage, c.lastSender == 'You'),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(('You', text, true)));
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final g = widget.conversation.group;
    final me = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      backgroundColor: ui.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
              child: Row(
                children: [
                  GlassCircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TapScale(
                      borderRadius: 12,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => _GroupDetailPage(group: g)),
                      ),
                      child: Row(
                        children: [
                          CommunityAvatar(color: g.color, initial: g.name[0], size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.literal(g.name),
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ui.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${g.memberCount} ${S.literal('members')} · ${S.literal('tap for details')}',
                                  style: TextStyle(
                                      fontSize: 11, color: ui.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: g.color.withValues(alpha: 0.03),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final (sender, text, isMe) = _messages[i];
                    final bubble = Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? LinearGradient(colors: [
                                g.color,
                                Color.lerp(g.color, Colors.black, 0.12)!,
                              ])
                            : null,
                        color: isMe ? null : ui.card,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: ui.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                sender,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: g.color,
                                ),
                              ),
                            ),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isMe ? Colors.white : ui.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );

                    // Group chats show who spoke — a small avatar sits
                    // next to every bubble, including your own outgoing
                    // ones (using your real saved photo when you've set
                    // one), not just incoming messages.
                    if (isMe) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.64),
                            child: bubble,
                          ),
                          const SizedBox(width: 8),
                          CommunityAvatar(
                            color: g.color,
                            initial: (me?.name.isNotEmpty ?? false)
                                ? me!.name[0]
                                : 'Y',
                            imagePath: me?.avatarPath,
                            size: 30,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CommunityAvatar(
                          color: widget.conversation.senderColor,
                          initial: sender[0],
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.64),
                          child: bubble,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: ui.card,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF202020).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ui.iconWell,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: S.literal('Message'),
                          hintStyle: TextStyle(
                              fontSize: 13, color: ui.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TapScale(
                    borderRadius: 22,
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          g.color,
                          Color.lerp(g.color, Colors.black, 0.12)!,
                        ]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: g.color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
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

