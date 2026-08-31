import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'home_ui.dart';

/// Notification dropdown anchored under the home bell. Nothing in the app
/// generates real notification events yet (see CLAUDE.md roadmap — a
/// Notifications table + insert-on-event wiring is future scope), so this
/// shows an honest empty state rather than fabricated activity.
class HomeNotificationsPanel extends StatelessWidget {
  const HomeNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
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
              child: Text(
                S.literal('Notifications'),
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ui.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, color: ui.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 30, color: ui.textSecondary),
                  const SizedBox(height: 10),
                  Text(
                    S.literal('No notifications yet'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ui.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.literal("You'll see activity on your posts and connections here."),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: ui.textSecondary, height: 1.4),
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
