import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _MarketAppBar(t: t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _MarketHero(t: t),
                    const SizedBox(height: 24),
                    _SectionLabel(t('categories')),
                    const SizedBox(height: 4),
                    Text(t('browse_products'), style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
                    const SizedBox(height: 14),
                    _CategoriesGrid(t: t),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(t('featured_listings')),
                              const SizedBox(height: 2),
                              Text(t('popular_products_desc'), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            t('see_all'),
                            style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FeaturedListings(t: t),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketAppBar extends StatelessWidget {
  const _MarketAppBar({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x183A2E29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x123A2E29)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.go('/'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('marketplace'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  t('earn_desc'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.marketplaceColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded, color: AppColors.marketplaceColor, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_business_rounded, color: AppColors.accent, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketHero extends StatelessWidget {
  const _MarketHero({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.marketplaceColor.withValues(alpha: 0.22),
            AppColors.earnColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.marketplaceColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.marketplaceColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.marketplaceColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t('sell_products'),
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t('sell_products_desc'),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 10, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(t('list_product_btn'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (t('cat_agri'), Icons.grass, AppColors.healthColor),
      (t('cat_crafts'), Icons.palette, AppColors.mentorshipColor),
      (t('cat_food_drink'), Icons.restaurant, AppColors.marketplaceColor),
      (t('cat_fashion'), Icons.checkroom, AppColors.thriveColor),
      (t('cat_beauty'), Icons.spa, AppColors.wellbeingColor),
      (t('cat_services'), Icons.handyman, AppColors.financeColor),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: categories.map((c) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: c.$3.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.$3.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: c.$3.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(c.$2, color: c.$3, size: 22),
                ),
                const SizedBox(height: 7),
                Text(
                  c.$1,
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FeaturedListings extends StatelessWidget {
  const _FeaturedListings({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    final listings = [
      const _Listing('Fresh Organic Vegetables', 'Sarah M. · Mukono', 'UGX 15,000', AppColors.healthColor, Icons.grass),
      const _Listing('Handwoven Baskets', 'Grace K. · Jinja', 'UGX 35,000', AppColors.mentorshipColor, Icons.palette),
      const _Listing('Shea Butter Soap', 'Peace N. · Gulu', 'UGX 8,000', AppColors.wellbeingColor, Icons.spa),
    ];

    return Column(
      children: listings.map((l) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x123A2E29),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x153A2E29)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: l.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(l.icon, color: l.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(l.seller, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.earnColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.price,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.earnColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Listing {
  const _Listing(this.title, this.seller, this.price, this.color, this.icon);
  final String title;
  final String seller;
  final String price;
  final Color color;
  final IconData icon;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
        color: AppColors.textHint,
      ),
    );
  }
}
