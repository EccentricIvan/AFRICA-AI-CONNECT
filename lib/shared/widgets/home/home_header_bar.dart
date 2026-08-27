import 'dart:io';

import 'package:flutter/material.dart';
import 'home_ui.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.userName,
    required this.greeting,
    required this.onAvatarTap,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onNotificationsTap,
    this.avatarPath,
  });

  final String userName;
  final String greeting;
  final VoidCallback onAvatarTap;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationsTap;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: _ProfileAvatar(avatarPath: avatarPath),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: ui.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ui.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _CircleIconBtn(
            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onThemeToggle,
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleIconBtn(Icons.notifications_outlined, onNotificationsTap),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: HomeUi.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ui.card, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// White circular avatar with minimal outline person (head + shoulders),
/// or the user's own saved photo when one has been set.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.avatarPath});
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ui.card,
              boxShadow: ui.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
              border: Border.all(color: ui.border, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarPath != null
                ? Image.file(File(avatarPath!), fit: BoxFit.cover)
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                        painter: _PersonOutlinePainter(color: ui.textPrimary)),
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: HomeUi.success,
                shape: BoxShape.circle,
                border: Border.all(color: ui.pageBg, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal line person: circle head + shoulder arc (matches screenshot style).
class _PersonOutlinePainter extends CustomPainter {
  const _PersonOutlinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final headR = size.width * 0.22;
    final headCy = size.height * 0.28;
    canvas.drawCircle(Offset(cx, headCy), headR, paint);

    final shoulderTop = size.height * 0.58;
    final shoulderBottom = size.height * 0.92;
    final shoulderWidth = size.width * 0.42;
    final arc = Path()
      ..moveTo(cx - shoulderWidth, shoulderBottom)
      ..quadraticBezierTo(
        cx,
        shoulderTop,
        cx + shoulderWidth,
        shoulderBottom,
      );
    canvas.drawPath(arc, paint);
  }

  @override
  bool shouldRepaint(covariant _PersonOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = HomeUi.of(context);
    return Material(
      color: ui.card,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: ui.card,
            shape: BoxShape.circle,
            boxShadow: ui.softShadow,
            border: ui.isDark ? Border.all(color: ui.border) : null,
          ),
          child: Icon(icon, size: 22, color: ui.textPrimary),
        ),
      ),
    );
  }
}
