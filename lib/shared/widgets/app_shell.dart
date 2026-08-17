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

  static const _destinations = [
    _NavDest('home', Icons.home_outlined, Icons.home_rounded, '/'),
    _NavDest(
      'learn',
      Icons.menu_book_outlined,
      Icons.menu_book_rounded,
      '/learn',
    ),
    _NavDest(
      'market',
      Icons.storefront_outlined,
      Icons.storefront_rounded,
      '/marketplace',
    ),
    _NavDest(
      'community',
      Icons.people_outline_rounded,
      Icons.people_rounded,
      '/community',
    ),
    _NavDest(
      'chat',
      Icons.chat_bubble_outline_rounded,
      Icons.chat_rounded,
      '/ai-chat',
    ),
  ];

  static const _sections = [
    _NavSection('nav_learn_earn', [
      _NavDest('home', Icons.home_outlined, Icons.home_rounded, '/'),
      _NavDest(
        'learn',
        Icons.menu_book_outlined,
        Icons.menu_book_rounded,
        '/learn',
      ),
      _NavDest(
        'market',
        Icons.storefront_outlined,
        Icons.storefront_rounded,
        '/marketplace',
      ),
      _NavDest(
        'finance',
        Icons.savings_outlined,
        Icons.savings_rounded,
        '/financial',
      ),
    ]),
    _NavSection('grow', [
      _NavDest(
        'mentors',
        Icons.diversity_1_outlined,
        Icons.diversity_1_rounded,
        '/mentorship',
      ),
      _NavDest('jobs', Icons.work_outline, Icons.work_rounded, '/jobs'),
      _NavDest(
        'skills',
        Icons.auto_awesome_outlined,
        Icons.auto_awesome_rounded,
        '/skills',
      ),
    ]),
    _NavSection('thrive', [
      _NavDest(
        'health',
        Icons.favorite_outline,
        Icons.favorite_rounded,
        '/health',
      ),
      _NavDest(
        'community',
        Icons.people_outlined,
        Icons.people_rounded,
        '/community',
      ),
      _NavDest(
        'wellbeing',
        Icons.spa_outlined,
        Icons.spa_rounded,
        '/wellbeing',
      ),
    ]),
    _NavSection('nav_account', [
      _NavDest(
        'ai_chat',
        Icons.chat_bubble_outline_rounded,
        Icons.chat_rounded,
        '/ai-chat',
      ),
      _NavDest(
        'profile',
        Icons.person_outlined,
        Icons.person_rounded,
        '/profile',
      ),
      _NavDest(
        'settings',
        Icons.settings_outlined,
        Icons.settings_rounded,
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
    String t(String key) => S.tr(context, ref, key);
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    if (isWide) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: Scaffold(
        key: mobileScaffoldKey,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSelector(),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        ),
        drawer: _AppDrawer(selectedIndex: selectedIndex, t: t),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _FloatingNavItem(
                      icon: _destinations[i].icon,
                      selectedIcon: _destinations[i].selectedIcon,
                      label: t(_destinations[i].label),
                      selected: mobileSelected == i,
                      onTap: () => context.go(_destinations[i].path),
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

/// Renders the grouped section list shared by the wide side-nav and the
/// mobile drawer. [selectedIndex] indexes into the flattened destination
/// list ([AppShell._allDestinations]); [onSelected] receives that same index.
class _GroupedNavList extends StatelessWidget {
  const _GroupedNavList({
    required this.selectedIndex,
    required this.onSelected,
    required this.t,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var idx = 0;
    for (final section in AppShell._sections) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
          child: Text(
            t(section.label).toUpperCase(),
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
            label: t(dest.label),
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
    return Container(
      width: 220,
      color: AppColors.surface,
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
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: _GroupedNavList(
              selectedIndex: selectedIndex,
              onSelected: (i) => context.go(AppShell._allDestinations[i].path),
              t: t,
            ),
          ),
          Container(height: 1, color: AppColors.border),
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
    return Drawer(
      backgroundColor: AppColors.surface,
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
                        t('app_tagline'),
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

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF26B2D) : const Color(0xFF6B6B6B);

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
              color: const Color(0xFFF26B2D),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest(this.label, this.icon, this.selectedIcon, this.path);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

class _NavSection {
  const _NavSection(this.label, this.items);
  final String label;
  final List<_NavDest> items;
}
