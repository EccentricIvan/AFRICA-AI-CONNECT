import 'package:flutter/material.dart';
import 'home_ui.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.userName,
    required this.greeting,
    required this.onAvatarTap,
    required this.onSearchTap,
    required this.onNotificationsTap,
  });

  final String userName;
  final String greeting;
  final VoidCallback onAvatarTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          GestureDetector(onTap: onAvatarTap, child: const _ProfileAvatar()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: HomeUi.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: HomeUi.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _CircleIconBtn(Icons.search_rounded, onSearchTap),
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
                    border: Border.all(color: HomeUi.card, width: 1.5),
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

/// White circular avatar with minimal outline person (head + shoulders).
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: CustomPaint(painter: _PersonOutlinePainter()),
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
                border: Border.all(color: HomeUi.pageBg, width: 2.5),
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
  const _PersonOutlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1A1A1A)
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
    final arc =
        Path()
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeUi.card,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: HomeUi.card,
            shape: BoxShape.circle,
            boxShadow: HomeUi.softShadow,
          ),
          child: Icon(icon, size: 22, color: HomeUi.textPrimary),
        ),
      ),
    );
  }
}
