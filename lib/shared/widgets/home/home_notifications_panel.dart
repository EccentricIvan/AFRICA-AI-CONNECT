import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'home_ui.dart';

class _NotificationItem {
  const _NotificationItem(
    this.icon,
    this.color,
    this.title,
    this.message,
    this.time, {
    this.unread = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool unread;
}

/// Instagram-style notification dropdown: most-recent-first list anchored
/// under the bell. Data is placeholder — nothing in the app currently
/// generates real notification events, so this proves the interaction
/// (open/scroll/dismiss) rather than a live feed.
class HomeNotificationsPanel extends StatelessWidget {
  const HomeNotificationsPanel({super.key});

  static List<_NotificationItem> get _items => [
    _NotificationItem(
      Icons.emoji_events_rounded,
      HomeUi.grow,
      S.literal('New badge unlocked'),
      S.literal(
        'You earned "Quick Learner" for finishing 3 lessons this week.',
      ),
      S.literal('2m ago'),
      unread: true,
    ),
    _NotificationItem(
      Icons.groups_rounded,
      HomeUi.thrive,
      S.literal('Community activity'),
      S.literal('Grace replied in Kampala Women Entrepreneurs.'),
      S.literal('25m ago'),
      unread: true,
    ),
    _NotificationItem(
      Icons.local_fire_department_rounded,
      HomeUi.accent,
      S.literal("Don't lose your streak"),
      S.literal("You're 1 lesson away from a 7-day streak."),
      S.literal('3h ago'),
      unread: true,
    ),
    _NotificationItem(
      Icons.work_outline_rounded,
      HomeUi.learn,
      S.literal('New job match'),
      S.literal('A "Digital Marketing Assistant" role matches your profile.'),
      S.literal('1d ago'),
    ),
    _NotificationItem(
      Icons.diversity_1_outlined,
      HomeUi.earn,
      S.literal('Mentorship request'),
      S.literal('Peace N. wants to connect with you as a mentee.'),
      S.literal('2d ago'),
    ),
    _NotificationItem(
      Icons.menu_book_rounded,
      HomeUi.learn,
      S.literal('Course update'),
      S.literal('A new module was added to Digital Skills 101.'),
      S.literal('4d ago'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    final unreadCount = _items.where((n) => n.unread).length;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: ui.card,
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: ui.isDark ? Border.all(color: ui.border) : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
              child: Row(
                children: [
                  Text(
                    S.literal('Notifications'),
                    style: TextStyle(
                      fontFamily: 'Saira',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ui.textPrimary,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: HomeUi.accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: ui.border),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: ui.border),
                itemBuilder: (context, i) => _NotificationTile(item: _items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: ui.isDark ? 0.22 : 0.14),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ui.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: ui.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: TextStyle(fontSize: 10.5, color: ui.textSecondary),
                ),
              ],
            ),
          ),
          if (item.unread) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: HomeUi.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
