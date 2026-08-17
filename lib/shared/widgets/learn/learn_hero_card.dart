import 'package:flutter/material.dart';
import '../tap_scale.dart';
import 'learn_ui.dart';

class LearnHeroCard extends StatelessWidget {
  const LearnHeroCard({
    super.key,
    required this.titleLine1,
    required this.titleLine2,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String titleLine1;
  final String titleLine2;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

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
          final titleSize = compact ? 24.0 : 28.0;
          final btnH = compact ? 46.0 : 50.0;

          return Container(
            width: outer.maxWidth,
            decoration: BoxDecoration(
              color: LearnUi.card,
              borderRadius: BorderRadius.circular(LearnUi.radiusHero),
              boxShadow: LearnUi.softShadow,
              image: const DecorationImage(
                image: AssetImage(LearnUi.heroBackgroundAsset),
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
                          Colors.white.withValues(alpha: 0.96),
                          Colors.white.withValues(alpha: 0.82),
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                        stops: const [0.0, 0.38, 0.62, 0.9],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad + 2, pad, pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$titleLine1\n',
                              style: TextStyle(
                                fontFamily: 'Saira',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: LearnUi.textPrimary,
                                height: 1.12,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: titleLine2,
                              style: TextStyle(
                                fontFamily: 'Saira',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: LearnUi.accent,
                                height: 1.12,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: compact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w400,
                          color: LearnUi.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: TapScale(
                              borderRadius: LearnUi.radiusBtn,
                              onTap: onPrimary,
                              child: Container(
                                height: btnH,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      LearnUi.accent,
                                      LearnUi.accentDeep,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    LearnUi.radiusBtn,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: LearnUi.accent.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        primaryLabel,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 9,
                            child: TapScale(
                              borderRadius: LearnUi.radiusBtn,
                              onTap: onSecondary,
                              child: Container(
                                height: btnH,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: LearnUi.card,
                                  borderRadius: BorderRadius.circular(
                                    LearnUi.radiusBtn,
                                  ),
                                  boxShadow: LearnUi.pillShadow,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.grid_view_rounded,
                                      size: 16,
                                      color: LearnUi.textPrimary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        secondaryLabel,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: LearnUi.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
