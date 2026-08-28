import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'language_selector.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static final mobileScaffoldKey = GlobalKey<ScaffoldState>();

  // Chat is pulled out of the flat row entirely and rendered as its own
  // raised orange FAB straddling the bar's top edge, centered between
  // these four flat items (2 left, 2 right) — matching the reference
  // "scan button" nav style rather than sitting flush as a 5th item.
  static const _destinations = [
    _NavDest('home', Icons.home_rounded, Icons.home_rounded, '/'),
    _NavDest(
      'learn',
      Icons.menu_book_rounded,
      Icons.menu_book_rounded,
      '/learn',
    ),
    _NavDest(
      'market',
      Icons.storefront_rounded,
      Icons.storefront_rounded,
      '/marketplace',
    ),
    _NavDest(
      'community',
      Icons.people_rounded,
      Icons.people_rounded,
      '/community',
    ),
    _NavDest('chat', Icons.chat_rounded, Icons.chat_rounded, '/ai-chat'),
  ];

  static const _chatPath = '/ai-chat';

  static const _sections = [
    _NavSection('learn_earn', [
      _NavDest('home', Icons.home_outlined, Icons.home, '/'),
      _NavDest('learn', Icons.menu_book_outlined, Icons.menu_book, '/learn'),
      _NavDest(
        'market',
        Icons.storefront_outlined,
        Icons.storefront,
        '/marketplace',
      ),
      _NavDest('finance', Icons.savings_outlined, Icons.savings, '/financial'),
    ]),
    _NavSection('grow', [
      _NavDest(
        'mentors',
        Icons.diversity_1_outlined,
        Icons.diversity_1,
        '/mentorship',
      ),
      _NavDest('jobs', Icons.work_outline, Icons.work, '/jobs'),
      _NavDest(
        'skills',
        Icons.auto_awesome_outlined,
        Icons.auto_awesome,
        '/skills',
      ),
    ]),
    _NavSection('thrive', [
      _NavDest('health', Icons.favorite_outline, Icons.favorite, '/health'),
      _NavDest('community', Icons.people_outlined, Icons.people, '/community'),
      _NavDest('wellbeing', Icons.spa_outlined, Icons.spa, '/wellbeing'),
    ]),
    _NavSection('account', [
      _NavDest('ai_chat', Icons.chat_outlined, Icons.chat, '/ai-chat'),
      _NavDest('profile', Icons.person_outlined, Icons.person, '/profile'),
      _NavDest(
        'settings',
        Icons.settings_outlined,
        Icons.settings,
        '/settings',
      ),
    ]),
  ];

  static List<_NavDest> get _allDestinations =>
      _sections.expand((s) => s.items).toList();

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final i = _allDestinations.indexWhere((d) => d.path == path);
    return i < 0 ? 0 : i;
  }

  int _mobileIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final i = _destinations.indexWhere((d) => d.path == path);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 640;
    final languageService = ref.watch(offlineLanguageServiceProvider);
    String t(String key) => languageService.t(key);

    if (isWide) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ac.bgTop, ac.bgBottom],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              _SideNav(selectedIndex: selectedIndex, t: t),
              Container(width: 1, color: AppColors.border),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    final mobileSelected = _mobileIndex(context);
    final isChatActive = GoRouterState.of(context).uri.path == _chatPath;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ac.bgTop, ac.bgBottom],
        ),
      ),
      child: Scaffold(
        key: mobileScaffoldKey,
        backgroundColor: Colors.transparent,
        body: child,
        drawer: _AppDrawer(selectedIndex: selectedIndex, t: t),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: mobileSelected,
            onDestinationSelected: (i) => context.go(_destinations[i].path),
            backgroundColor: Colors.transparent,
            destinations:
                _destinations
                    .map(
                      (d) => NavigationDestination(
                        icon: Icon(d.icon, color: AppColors.textHint),
                        selectedIcon: Icon(
                          d.selectedIcon,
                          color: AppColors.accent,
                        ),
                        label: t(d.labelKey),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

/// Renders the grouped section list shared by the wide side-nav and the
/// mobile drawer. [selectedIndex] indexes into the flattened destination
/// list ([AppShell._allDestinations]); [onSelected] receives that same index.
class _GroupedNavList extends StatelessWidget {
  const _GroupedNavList({
    required this.selectedIndex,
    required this.t,
    required this.onSelected,
  });
  final int selectedIndex;
  final String Function(String) t;
  final ValueChanged<int> onSelected;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final children = <Widget>[];
    var idx = 0;
    for (final section in AppShell._sections) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Text(
            t(section.labelKey).toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.textHint,
            ),
          ),
        ),
      );
      for (final dest in section.items) {
        final i = idx;
        children.add(
          _NavTile(
            dest: dest,
            label: t(dest.labelKey),
            selected: selectedIndex == i,
            onTap: () => onSelected(i),
          ),
        );
        idx++;
      }
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: children,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.dest,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final _NavDest dest;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color:
              selected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 32,
                  color: selected ? AppColors.accent : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? dest.selectedIcon : dest.icon,
                          color:
                              selected ? AppColors.accent : AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color:
                                  selected
                                      ? AppColors.accent
                                      : AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
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

class _SideNav extends StatelessWidget {
  const _SideNav({required this.selectedIndex, required this.t});
  final int selectedIndex;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      width: 220,
      color: ac.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/branding/app_icon_mark.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  t('app_name'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: ac.border),
          Expanded(
            child: _GroupedNavList(
              selectedIndex: selectedIndex,
              t: t,
              onSelected: (i) => context.go(AppShell._allDestinations[i].path),
              t: t,
            ),
          ),
          Container(height: 1, color: ac.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${t('online')} - v1.0',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
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

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.selectedIndex, required this.t});
  final int selectedIndex;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Drawer(
      backgroundColor: ac.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/branding/app_icon_mark.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('app_name'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        t('connecting_women_opportunity'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.border,
            ),
            Expanded(
              child: _GroupedNavList(
                selectedIndex: selectedIndex,
                t: t,
                onSelected: (i) {
                  context.go(AppShell._allDestinations[i].path);
                  Navigator.pop(context);
                },
                t: t,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _activeColor = Color(0xFFF26B2D);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _activeColor : AppColors.of(context).textHint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            width: selected ? 18 : 0,
            decoration: BoxDecoration(
              color: _activeColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chat destination, pulled out of the flat nav row and rendered as
/// a raised circular FAB straddling the bar's top edge — same "stand out"
/// treatment as a scan/action button in a typical 5-item nav, in the
/// brand's orange instead of a flat icon.
class _ChatFabButton extends StatelessWidget {
  const _ChatFabButton({
    required this.active,
    required this.ringColor,
    required this.onTap,
  });

  final bool active;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor,
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF28A1A), Color(0xFFE07812)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x73F28A1A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              active ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDest {
  const _NavDest(this.labelKey, this.icon, this.selectedIcon, this.path);
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

class _NavSection {
  const _NavSection(this.labelKey, this.items);
  final String labelKey;
  final List<_NavDest> items;
}
