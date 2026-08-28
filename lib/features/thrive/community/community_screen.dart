import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageService = ref.watch(offlineLanguageServiceProvider);
    String t(String key) => languageService.t(key);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('community')),
        actions: [
          IconButton(icon: const Icon(Icons.group_add), onPressed: () {}),
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
                child: _SearchField(
                  hint: searchHint,
                  onChanged: onSearchChanged,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
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
    final list =
        q.isEmpty
            ? _CommunityData.conversations
            : _CommunityData.conversations
                .where(
                  (c) =>
                      c.group.name.toLowerCase().contains(q) ||
                      c.lastMessage.toLowerCase().contains(q),
                )
                .toList();

    return _TabScaffold(
      title: S.literal('Chats'),
      searchHint: S.literal('Search your communities'),
      onSearchChanged: (v) => setState(() => _query = v),
      child:
          list.isEmpty
              ? Center(
                child: Text(
                  S.literal('No conversations found'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CommunityUi.textSecondary,
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children:
                    list.map((c) => _ConversationRow(conversation: c)).toList(),
              ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final q = _query.trim().toLowerCase();
    final list =
        q.isEmpty
            ? _CommunityData.posts
            : _CommunityData.posts
                .where(
                  (post) =>
                      post.author.toLowerCase().contains(q) ||
                      post.content.toLowerCase().contains(q),
                )
                .toList();

    return _TabScaffold(
      title: S.literal('Feed'),
      searchHint: S.literal('Search posts from your communities'),
      onSearchChanged: (v) => setState(() => _query = v),
      child:
          list.isEmpty
              ? Center(
                child: Text(
                  S.literal('No posts found'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CommunityUi.textSecondary,
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children:
                    list.map((post) => _FeedPostCard(post: post)).toList(),
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
      builder:
          (_) => _FilterSheet(
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
    final list =
        _CommunityData.groups.where((g) {
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
            color:
                _hasActiveFilters
                    ? CommunityUi.accent.withValues(alpha: 0.14)
                    : CommunityUi.card,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 20,
            color:
                _hasActiveFilters
                    ? CommunityUi.accent
                    : CommunityUi.textSecondary,
          ),
        ),
      ),
      child:
          list.isEmpty
              ? Center(
                child: Text(
                  S.literal('No groups found'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CommunityUi.textSecondary,
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: list.map((g) => _DiscoverGroupRow(group: g)).toList(),
              ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialCategories,
    required this.initialLocations,
  });
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

  static const _locationOptions = ['Kampala', 'Gulu', 'Mbale', 'Jinja'];

  Widget _chipRow(String label, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.literal(label),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: CommunityUi.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children:
              options.map((c) {
                final isSelected = selected.contains(c);
                return ChoiceChip(
                  label: Text(c),
                  selected: isSelected,
                  onSelected:
                      (_) => setState(
                        () => isSelected ? selected.remove(c) : selected.add(c),
                      ),
                  selectedColor: CommunityUi.accent.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? CommunityUi.accent
                            : CommunityUi.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? CommunityUi.accent : CommunityUi.border,
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
            style: const TextStyle(
              fontFamily: 'Saira',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CommunityUi.textPrimary,
            ),
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
              onTap: () => Navigator.of(context).pop((_categories, _locations)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CommunityUi.accent, CommunityUi.accentDeep],
                  ),
                  borderRadius: BorderRadius.circular(CommunityUi.radiusBtn),
                ),
                child: Text(
                  S.literal('Apply'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
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
          hintStyle: const TextStyle(
            fontSize: 14,
            color: CommunityUi.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 21,
            color: CommunityUi.textSecondary,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 52),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// A modern abstract-gradient stand-in for a real photo: layered soft
/// color washes with a subtle camera watermark — no photo asset exists
/// yet.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.color, this.radius = 12});
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(color, Colors.white, 0.55)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.black, 0.15)!.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Positioned(
            left: -18,
            top: -18,
            child: _blob(70, light.withValues(alpha: 0.5)),
          ),
          Positioned(
            right: -14,
            bottom: -20,
            child: _blob(
              90,
              Color.lerp(color, Colors.white, 0.2)!.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Icon(
              Icons.photo_camera_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
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
  const _JoinButton({required this.color, required this.groupName});
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
          gradient:
              _joined
                  ? null
                  : LinearGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.15)!],
                  ),
          color: _joined ? CommunityUi.iconWell : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              _joined
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
              Icon(
                _joined ? Icons.check_rounded : Icons.add_rounded,
                size: 14,
                color: _joined ? color : Colors.white,
              ),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommunityHero(t: t),
                const SizedBox(height: 24),
                SectionHeader(
                  title: t('your_groups'),
                  subtitle: t('your_groups_desc'),
                ),
                const SizedBox(height: 12),
                _EmptyGroupsState(t: t),
                const SizedBox(height: 24),
                SectionHeader(
                  title: t('discover_groups'),
                  subtitle: t('discover_groups_desc'),
                ),
                const SizedBox(height: 12),
                _DiscoverGroups(t: t),
                const SizedBox(height: 24),
                SectionHeader(
                  title: t('community_feed'),
                  subtitle: t('community_feed_desc'),
                ),
                const SizedBox(height: 12),
                _CommunityFeed(t: t),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.t});
  final String Function(String) t;

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
                      colors: [
                        g.color,
                        Color.lerp(g.color, Colors.black, 0.15)!,
                      ],
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
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
                          color: g.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(
                    color: g.color,
                    count: '${g.memberCount} members',
                  ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.communityColor.withValues(alpha: 0.15),
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
  const _Group(
    this.name,
    this.members,
    this.icon,
    this.color,
    this.category,
    this.location,
  );
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
    _Member('Sarah M.', [
      'Entrepreneur',
      'Mentor',
      'Community Leader',
    ], isAdmin: true),
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
                      borderRadius: BorderRadius.circular(
                        CommunityUi.radiusHero,
                      ),
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
                          color: g.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MemberAvatars(
                    color: g.color,
                    count: '${g.memberCount} members',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${S.literal('Created by')} ${creator.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CommunityUi.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: g.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: g.color,
                          size: 16,
                        ),
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
                  ..._mockMembers.map(
                    (m) => _MemberListRow(color: g.color, member: m),
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
                Text(
                  t('community_hero_title'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  t('community_hero_desc'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.communityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people,
              color: AppColors.communityColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState({required this.t});
  final String Function(String) t;

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
      onTap:
          () => Navigator.of(context).push(
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
          color:
              c.unread > 0
                  ? CommunityUi.textPrimary
                  : CommunityUi.textSecondary,
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
            c.time,
            style: const TextStyle(
              fontSize: 11,
              color: CommunityUi.textSecondary,
            ),
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
                const SizedBox(height: 6),
                Text(
                  S.literal(
                    "Connect with women's groups, share experiences, support each other, and grow together.",
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _Conversation {
  const _Conversation(
    this.group,
    this.lastSender,
    this.lastMessage,
    this.time, {
    this.unread = 0,
    required this.senderColor,
  });
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
      (
        c.lastSender,
        'Hey everyone, hope you\'re all doing well this week!',
        c.lastSender == 'You',
      ),
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
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _GroupDetailPage(group: g),
                            ),
                          ),
                      child: Row(
                        children: [
                          CommunityAvatar(
                            color: g.color,
                            initial: g.name[0],
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  S.literal(g.name),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CommunityUi.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${g.memberCount} ${S.literal('members')} · ${S.literal('tap for details')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CommunityUi.textSecondary,
                                  ),
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
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isMe
                                ? LinearGradient(
                                  colors: [
                                    g.color,
                                    Color.lerp(g.color, Colors.black, 0.12)!,
                                  ],
                                )
                                : null,
                        color: isMe ? null : CommunityUi.card,
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
                      return Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                          ),
                          child: bubble,
                        ),
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
                            maxWidth: MediaQuery.sizeOf(context).width * 0.64,
                          ),
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
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: CommunityUi.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
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
                        gradient: LinearGradient(
                          colors: [
                            g.color,
                            Color.lerp(g.color, Colors.black, 0.12)!,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: g.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            child: const Icon(
              Icons.people,
              color: AppColors.communityColor,
              size: 28,
            ),
          ),
        ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Feed / posts ────────────────────────

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post});
  final _Post post;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final p = post;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(CommunityUi.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups, size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            t('no_groups_yet'),
            style: Theme.of(context).textTheme.titleMedium,
          Row(
            children: [
              CommunityAvatar(color: p.color, initial: p.author[0], size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: CommunityUi.textPrimary,
                      ),
                    ),
                    Text(
                      S.literal(p.time),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CommunityUi.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t('join_or_create_group'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: Text(t('create_group')),
          ),
        ],
      ),
    );
  }
}

class _DiscoverGroups extends StatelessWidget {
  const _DiscoverGroups({required this.t});
  final String Function(String) t;

  static const _groups = [
    _Group(
      'group_kampala_women_entrepreneurs',
      124,
      Icons.trending_up,
      AppColors.earnColor,
    ),
    _Group(
      'group_digital_skills_network',
      89,
      Icons.computer,
      AppColors.skillsColor,
    ),
    _Group(
      'group_farmers_united',
      256,
      Icons.agriculture,
      AppColors.healthColor,
    ),
    _Group(
      'group_young_mothers_support',
      67,
      Icons.child_care,
      AppColors.thriveColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          _groups.map((g) {
            return Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: g.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(g.icon, color: g.color, size: 22),
                ),
                title: Text(
                  t(g.nameKey),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text('${g.memberCount} ${t('members')}'),
                trailing: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(t('join'), style: const TextStyle(fontSize: 12)),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _Group {
  const _Group(this.nameKey, this.memberCount, this.icon, this.color);
  final String nameKey;
  final int memberCount;
  final IconData icon;
  final Color color;
}

class _CommunityFeed extends StatelessWidget {
  const _CommunityFeed({required this.t});
  final String Function(String) t;

  static const _posts = [
    _Post(
      'Sarah M.',
      'post_digital_skills_done',
      'time_2_hours_ago',
      AppColors.skillsColor,
    ),
    _Post(
      'Grace K.',
      'post_wholesale_order',
      'time_5_hours_ago',
      AppColors.earnColor,
    ),
    _Post(
      'Peace N.',
      'post_sacco_gulu',
      'time_1_day_ago',
      AppColors.financeColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          _posts.map((p) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: p.color.withValues(alpha: 0.12),
                          child: Text(
                            p.author[0],
                            style: TextStyle(
                              color: p.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                t(p.timeKey),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t(p.contentKey),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FeedAction(Icons.favorite_border, t('like')),
                        const SizedBox(width: 16),
                        _FeedAction(Icons.chat_bubble_outline, t('comment')),
                        const SizedBox(width: 16),
                        _FeedAction(Icons.share_outlined, t('share')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _Post {
  const _Post(this.author, this.contentKey, this.timeKey, this.color);
  final String author;
  final String contentKey;
  final String timeKey;
  final Color color;
  final int imageCount;
}

class _FeedAction extends StatelessWidget {
  const _FeedAction(this.icon, this.label, {this.light = false});
  final IconData icon;
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final ui = CommunityUi.of(context);
    final color =
        light ? Colors.white.withValues(alpha: 0.9) : ui.textSecondary;
    return TapScale(
      borderRadius: 10,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              S.literal(label),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
