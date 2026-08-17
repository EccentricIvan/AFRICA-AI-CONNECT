import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/market/market_category_card.dart';
import '../../../shared/widgets/market/market_empty_listings.dart';
import '../../../shared/widgets/market/market_header_bar.dart';
import '../../../shared/widgets/market/market_hero_card.dart';
import '../../../shared/widgets/market/market_listing_card.dart';
import '../../../shared/widgets/market/market_section_header.dart';
import '../../../shared/widgets/market/market_ui.dart';

/// Copies a user-picked image into the app's own persistent documents
/// directory (not the OS picker's temp/cache path, which isn't guaranteed
/// to survive) and returns the new path, or null if the user cancelled.
Future<String?> _pickAndSaveImage() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) return null;

  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'marketplace_photos'));
  if (!await photosDir.exists()) await photosDir.create(recursive: true);

  final destPath = p.join(
    photosDir.path,
    '${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedPath)}',
  );
  await File(pickedPath).copy(destPath);
  return destPath;
}

/// Single source of truth for category key <-> label/icon/color, shared by
/// the category grid, the listing cards, and the create-listing sheet.
const _categoryMeta = [
  (
    key: 'agriculture',
    labelKey: 'cat_agri',
    icon: Icons.grass_outlined,
    color: Color(0xFFD65C6A),
  ),
  (
    key: 'crafts',
    labelKey: 'cat_crafts',
    icon: Icons.palette_outlined,
    color: Color(0xFF7C5CBF),
  ),
  (
    key: 'food_drink',
    labelKey: 'cat_food_drink',
    icon: Icons.restaurant_outlined,
    color: MarketUi.accent,
  ),
  (
    key: 'fashion',
    labelKey: 'cat_fashion',
    icon: Icons.checkroom_outlined,
    color: Color(0xFF4A6FA5),
  ),
  (
    key: 'beauty',
    labelKey: 'cat_beauty',
    icon: Icons.spa_outlined,
    color: Color(0xFFC4783A),
  ),
  (
    key: 'services',
    labelKey: 'cat_services',
    icon: Icons.handyman_outlined,
    color: Color(0xFF4D8B55),
  ),
];

typedef _CategoryMeta =
    ({String key, String labelKey, IconData icon, Color color});

_CategoryMeta _metaFor(String key) => _categoryMeta.firstWhere(
  (c) => c.key == key,
  orElse: () => _categoryMeta.first,
);

String _formatUgx(double price) {
  final s = price.toInt().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'UGX $buf';
}

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    String t(String key) => S.tr(context, ref, key);

    void openListingSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: MarketUi.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => const _ListProductSheet(),
      );
    }

    void clearCategoryFilter() {
      ref.read(selectedMarketplaceCategoryProvider.notifier).state = null;
    }

    return Scaffold(
      backgroundColor: MarketUi.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            MarketHeaderBar(
              title: t('marketplace'),
              subtitle: t('earn_desc'),
              onBack: () => context.go('/'),
              onSearch: () {},
              onAdd: openListingSheet,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarketHeroCard(
                      title: t('sell_products'),
                      body: t('sell_products_desc'),
                      ctaLabel: t('list_product_btn'),
                      onCta: openListingSheet,
                    ),
                    const SizedBox(height: 28),
                    MarketSectionHeader(
                      title: t('categories'),
                      trailing: t('see_all'),
                      onTrailingTap: clearCategoryFilter,
                    ),
                    const SizedBox(height: 14),
                    _CategoriesGrid(t: t),
                    const SizedBox(height: 28),
                    MarketSectionHeader(
                      title: t('featured_listings'),
                      trailing: t('see_all'),
                      onTrailingTap: clearCategoryFilter,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('popular_products_desc'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: MarketUi.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FeaturedListings(t: t, onAdd: openListingSheet),
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

class _CategoriesGrid extends ConsumerWidget {
  const _CategoriesGrid({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMarketplaceCategoryProvider);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.88,
      children:
          _categoryMeta.map((c) {
            final isSelected = selected == c.key;
            return MarketCategoryCard(
              label: t(c.labelKey),
              icon: c.icon,
              accent: c.color,
              selected: isSelected,
              onTap:
                  () =>
                      ref
                          .read(selectedMarketplaceCategoryProvider.notifier)
                          .state = isSelected ? null : c.key,
            );
          }).toList(),
    );
  }
}

class _FeaturedListings extends ConsumerWidget {
  const _FeaturedListings({required this.t, required this.onAdd});
  final String Function(String) t;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(marketplaceListingsProvider);
    final hasFilter = ref.watch(selectedMarketplaceCategoryProvider) != null;

    return listingsAsync.when(
      loading:
          () => const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MarketUi.accent,
              ),
            ),
          ),
      error:
          (e, _) => const Text(
            'Could not load listings',
            style: TextStyle(fontSize: 13, color: MarketUi.textSecondary),
          ),
      data: (listings) {
        if (listings.isEmpty) {
          return MarketEmptyListings(
            title:
                hasFilter ? t('no_listings_in_category') : t('no_listings_yet'),
            subtitle:
                hasFilter
                    ? t('browse_products')
                    : 'Be the first to list a product!',
            ctaLabel: t('list_product_btn'),
            onCta: onAdd,
            showClearFilter: hasFilter,
            clearLabel: t('clear_filter'),
            onClear:
                () =>
                    ref
                        .read(selectedMarketplaceCategoryProvider.notifier)
                        .state = null,
          );
        }
        return Column(
          children:
              listings.map((l) {
                final meta = _metaFor(l.category);
                final sellerLine =
                    l.location != null
                        ? '${l.sellerName} · ${l.location}'
                        : l.sellerName;
                return MarketListingCard(
                  title: l.title,
                  sellerLine: sellerLine,
                  priceLabel: _formatUgx(l.price),
                  fallbackIcon: meta.icon,
                  imagePath: l.imagePath,
                );
              }).toList(),
        );
      },
    );
  }
}

class _ListProductSheet extends ConsumerStatefulWidget {
  const _ListProductSheet();

  @override
  ConsumerState<_ListProductSheet> createState() => _ListProductSheetState();
}

class _ListProductSheetState extends ConsumerState<_ListProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  String? _imagePath;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _t(String key) => S.tr(context, ref, key);

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final path = await _pickAndSaveImage();
    if (!mounted) return;
    setState(() {
      _pickingImage = false;
      if (path != null) _imagePath = path;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('select_category_error'))));
      return;
    }
    final seller = ref.read(currentUserProvider).valueOrNull?.name;
    if (seller == null) return;

    setState(() => _saving = true);
    await ref
        .read(marketplaceDaoProvider)
        .addListing(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory!,
          sellerName: seller,
          location:
              _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
          imagePath: _imagePath,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = ref.watch(currentUserProvider).valueOrNull?.name ?? '…';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MarketUi.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _t('list_product_btn'),
                  style: const TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: MarketUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_t('listing_as')} $sellerName',
                  style: const TextStyle(
                    fontSize: 13,
                    color: MarketUi.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickingImage ? null : _pickImage,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: MarketUi.iconWell,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MarketUi.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          _pickingImage
                              ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MarketUi.accent,
                                ),
                              )
                              : _imagePath != null
                              ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap:
                                          () =>
                                              setState(() => _imagePath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                              : const Icon(
                                Icons.add_a_photo_outlined,
                                color: MarketUi.textSecondary,
                                size: 28,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _t('listing_title_hint'),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? _t('listing_title_error')
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: _t('listing_price_hint'),
                  ),
                  validator: (v) {
                    final parsed = double.tryParse((v ?? '').trim());
                    return (parsed == null || parsed <= 0)
                        ? _t('listing_price_error')
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _t('select_category_label'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MarketUi.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _categoryMeta.map((c) {
                        final isSelected = _selectedCategory == c.key;
                        return ChoiceChip(
                          label: Text(_t(c.labelKey)),
                          selected: isSelected,
                          onSelected:
                              (_) => setState(() => _selectedCategory = c.key),
                          selectedColor: c.color.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color:
                                isSelected ? c.color : MarketUi.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: isSelected ? c.color : MarketUi.border,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(hintText: _t('location_hint')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MarketUi.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MarketUi.radiusBtn),
                      ),
                    ),
                    child:
                        _saving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(_t('list_product_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
