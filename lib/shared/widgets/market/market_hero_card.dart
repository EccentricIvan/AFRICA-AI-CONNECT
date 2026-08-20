import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'market_ui.dart';

class MarketHeroCard extends StatelessWidget {
  const MarketHeroCard({
    super.key,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final ui = MarketUi.of(context);
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

          return Container(
            width: outer.maxWidth,
            constraints: BoxConstraints(
              minHeight: compact ? 220 : 248,
            ),
            decoration: BoxDecoration(
              color: ui.card,
              borderRadius: BorderRadius.circular(MarketUi.radiusHero),
              boxShadow: ui.softShadow,
              image: const DecorationImage(
                image: AssetImage(MarketUi.heroBackgroundAsset),
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
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
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
                              // Fixed light tone, not theme-reactive — this
                              // badge sits on the hero's own bright photo
                              // wash, which doesn't change with app theme.
                              color: MarketUi.light.iconWell,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              size: 22,
                              color: MarketUi.accent,
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
                          SizedBox(width: compact ? 72 : 100),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(right: compact ? 88 : 120),
                        child: Text(
                          body,
                          style: TextStyle(
                            fontSize: compact ? 12.5 : 13.5,
                            fontWeight: FontWeight.w400,
                            // Fixed — same reasoning as the icon badge above.
                            color: MarketUi.light.textSecondary,
                            height: 1.45,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TapScale(
                        borderRadius: MarketUi.radiusBtn,
                        onTap: onCta,
                        child: Container(
                          height: compact ? 44 : 48,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [MarketUi.accent, MarketUi.accentDeep],
                            ),
                            borderRadius:
                                BorderRadius.circular(MarketUi.radiusBtn),
                            boxShadow: [
                              BoxShadow(
                                color: MarketUi.accent.withValues(alpha: 0.35),
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
