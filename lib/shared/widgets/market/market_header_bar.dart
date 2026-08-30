import 'package:flutter/material.dart';
import '../glass/glass_circle_btn.dart';
import 'market_ui.dart';

class MarketHeaderBar extends StatelessWidget {
  const MarketHeaderBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onSearch,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ui = MarketUi.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GlassCircleBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ui.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: ui.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GlassCircleBtn(icon: Icons.search_rounded, onTap: onSearch),
          const SizedBox(width: 8),
          _GlassAddBtn(onTap: onAdd),
        ],
      ),
    );
  }
}

class _GlassAddBtn extends StatelessWidget {
  const _GlassAddBtn({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = MarketUi.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ui.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ui.border),
            boxShadow: ui.softShadow,
          ),
          child: const Icon(
            Icons.storefront_outlined,
            size: 20,
            color: MarketUi.accent,
          ),
        ),
      ),
    );
  }
}
