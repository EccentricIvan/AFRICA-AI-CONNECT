import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'home_ui.dart';

/// Hero with light card_background asset — no floating icons.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onlineLabel,
    required this.streakLabel,
    required this.ctaLabel,
    required this.onCta,
  });

  final String title;
  final String subtitle;
  final String onlineLabel;
  final String streakLabel;
  final String ctaLabel;
  final VoidCallback onCta;

  List<InlineSpan> _titleSpans(String raw, double fontSize) {
    final dark = TextStyle(
      fontFamily: 'Saira',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: HomeUi.textPrimary,
      height: 1.1,
      letterSpacing: -0.4,
    );
    final orange = TextStyle(
      fontFamily: 'Saira',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: HomeUi.accent,
      height: 1.1,
      letterSpacing: -0.4,
    );

    final cleaned = raw.replaceAll('\n', ' ').trim();
    final futureIdx = cleaned.toLowerCase().indexOf('future');
    if (futureIdx > 0) {
      final before = cleaned.substring(0, futureIdx).trimRight();
      final after = cleaned.substring(futureIdx);
      return [
        TextSpan(text: '$before\n', style: dark),
        TextSpan(text: after, style: orange),
      ];
    }
    if (futureIdx == 0) {
      return [TextSpan(text: cleaned, style: orange)];
    }
    return [TextSpan(text: cleaned, style: dark)];
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: scaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.05),
      ),
      child: LayoutBuilder(
        builder: (context, outer) {
          final width = outer.maxWidth;
          final compact = width < 360;
          final titleSize = compact ? 24.0 : 30.0;
          final subtitleSize = compact ? 12.0 : 13.5;
          final ctaHeight = compact ? 44.0 : 52.0;
          final pad = compact ? 16.0 : 20.0;

          return Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeUi.radiusHero),
              boxShadow: HomeUi.softShadow,
              border: Border.all(color: HomeUi.border),
              image: const DecorationImage(
                image: AssetImage(HomeUi.heroBackgroundAsset),
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Soft left wash so dark text stays readable over the map.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.42, 0.78],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _HeroChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: HomeUi.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  onlineLabel,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: HomeUi.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _HeroChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 12,
                                  color: HomeUi.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  streakLabel,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: HomeUi.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Text.rich(
                        TextSpan(children: _titleSpans(title, titleSize)),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          height: 1.4,
                          color: HomeUi.textSecondary.withValues(alpha: 0.95),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      TapScale(
                        onTap: onCta,
                        borderRadius: 18,
                        child: Container(
                          height: ctaHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [HomeUi.accent, HomeUi.accentDeep],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HomeUi.accent.withValues(alpha: 0.28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  ctaLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 13 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: compact ? 26 : 28,
                                height: compact ? 26 : 28,
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: compact ? 14 : 16,
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: HomeUi.border),
      ),
      child: child,
    );
  }
}
