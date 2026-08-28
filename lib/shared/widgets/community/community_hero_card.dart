import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'community_ui.dart';

/// The exact hero shape Marketplace uses: a real photo bleeding in from
/// the right, a white fade scrim so text stays legible over it, an
/// icon-well badge, Saira heading — Community's own content (avatar
/// cluster + "Join N women..." line, then the create-community CTA)
/// slotted into that same scaffold.
class CommunityHeroCard extends StatelessWidget {
  const CommunityHeroCard({
    super.key,
    required this.title,
    required this.body,
    required this.membershipLine,
    required this.avatarColors,
    required this.ctaLabel,
    required this.onCta,
  });

  final String title;
  final String body;
  final String membershipLine;
  final List<Color> avatarColors;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.05),
      ),
      child: LayoutBuilder(
        builder: (context, outer) {
          final compact = outer.maxWidth < 360;
          final pad = compact ? 16.0 : 20.0;
          final titleSize = compact ? 18.0 : 20.0;
          // The photo fills the card's full width (its 16:9 crop is wider
          // than the card is tall), so the safe text zone scales with card
          // width, not a fixed px amount — otherwise wide windows push the
          // subject far enough left that fixed padding stops covering it.
          final photoReserve = (outer.maxWidth * 0.44).clamp(100.0, 230.0);

          final ui = CommunityUi.of(context);
          return Container(
            width: outer.maxWidth,
            // Trimmed to match the content's real height (title+body+
            // avatar row+button) so the card doesn't carry dead space below
            // the button — it was previously taller than its own content.
            constraints: BoxConstraints(minHeight: compact ? 244 : 262),
            decoration: BoxDecoration(
              color: ui.card,
              borderRadius: BorderRadius.circular(CommunityUi.radiusHero),
              boxShadow: ui.softShadow,
              image: const DecorationImage(
                image: AssetImage(CommunityUi.heroBackgroundAsset),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          Colors.white.withValues(alpha: 0.78),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        stops: const [0.0, 0.36, 0.62, 0.88],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      pad, pad, pad, compact ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CommunityUi.light.iconWell,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              size: 22,
                              color: CommunityUi.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Saira',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D2A1E),
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: photoReserve),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.only(right: photoReserve),
                        child: Text(
                          body,
                          style: TextStyle(
                            fontSize: compact ? 12.5 : 13.5,
                            color: CommunityUi.light.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Pushed further down, closer to the banner's own
                      // bottom edge, instead of crowding the body text.
                      const SizedBox(height: 28),
                      Padding(
                        // Same right-edge stop as the body text above —
                        // this row must never run into the photo either.
                        padding: EdgeInsets.only(right: photoReserve),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _AvatarCluster(colors: avatarColors),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                membershipLine,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: CommunityUi.light.textPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TapScale(
                        borderRadius: CommunityUi.radiusBtn,
                        onTap: onCta,
                        child: Container(
                          height: compact ? 44 : 48,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [CommunityUi.accent, CommunityUi.accentDeep],
                            ),
                            borderRadius:
                                BorderRadius.circular(CommunityUi.radiusBtn),
                            boxShadow: [
                              BoxShadow(
                                color: CommunityUi.accent.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster({required this.colors});
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: colors.length * 20.0 + 18,
      height: 38,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
