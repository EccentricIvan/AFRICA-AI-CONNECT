import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/providers/database_provider.dart';

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
  (key: 'agriculture', labelKey: 'cat_agri', icon: Icons.grass, color: AppColors.healthColor),
  (key: 'crafts', labelKey: 'cat_crafts', icon: Icons.palette, color: AppColors.mentorshipColor),
  (key: 'food_drink', labelKey: 'cat_food_drink', icon: Icons.restaurant, color: AppColors.marketplaceColor),
  (key: 'fashion', labelKey: 'cat_fashion', icon: Icons.checkroom, color: AppColors.thriveColor),
  (key: 'beauty', labelKey: 'cat_beauty', icon: Icons.spa, color: AppColors.wellbeingColor),
  (key: 'services', labelKey: 'cat_services', icon: Icons.handyman, color: AppColors.financeColor),
];

typedef _CategoryMeta = ({String key, String labelKey, IconData icon, Color color});

_CategoryMeta _metaFor(String key) =>
    _categoryMeta.firstWhere((c) => c.key == key, orElse: () => _categoryMeta.first);

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
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const _ListProductSheet(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _MarketAppBar(t: t, onAdd: openListingSheet),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _MarketHero(t: t, onAdd: openListingSheet),
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
                          onTap: () => ref.read(selectedMarketplaceCategoryProvider.notifier).state = null,
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
  const _MarketAppBar({required this.t, required this.onAdd});
  final String Function(String) t;
  final VoidCallback onAdd;

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
          // Search/browse is a deliberate deferral, not an oversight — see
          // CLAUDE.md's Roadmap. This slice covers listing + filtering only.
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
            onTap: onAdd,
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
  const _MarketHero({required this.t, required this.onAdd});
  final String Function(String) t;
  final VoidCallback onAdd;

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
            onTap: onAdd,
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
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: _categoryMeta.map((c) {
        final isSelected = selected == c.key;
        return GestureDetector(
          onTap: () => ref.read(selectedMarketplaceCategoryProvider.notifier).state =
              isSelected ? null : c.key,
          child: Container(
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: isSelected ? 0.22 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.color.withValues(alpha: isSelected ? 0.6 : 0.2), width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(c.icon, color: c.color, size: 22),
                ),
                const SizedBox(height: 7),
                Text(
                  t(c.labelKey),
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

class _FeaturedListings extends ConsumerWidget {
  const _FeaturedListings({required this.t});
  final String Function(String) t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(marketplaceListingsProvider);
    final hasFilter = ref.watch(selectedMarketplaceCategoryProvider) != null;

    return listingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const Text(
        'Could not load listings',
        style: TextStyle(fontSize: 13, color: AppColors.textHint),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return _EmptyListings(
            message: hasFilter ? t('no_listings_in_category') : t('no_listings_yet'),
            showClearFilter: hasFilter,
            clearLabel: t('clear_filter'),
            onClear: () => ref.read(selectedMarketplaceCategoryProvider.notifier).state = null,
          );
        }
        return Column(
          children: listings.map((l) {
            final meta = _metaFor(l.category);
            final sellerLine = l.location != null ? '${l.sellerName} · ${l.location}' : l.sellerName;
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: l.imagePath != null
                        ? Image.file(
                            File(l.imagePath!),
                            width: 52, height: 52, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ListingIconFallback(meta: meta),
                          )
                        : _ListingIconFallback(meta: meta),
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
                        Text(sellerLine, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
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
                      _formatUgx(l.price),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.earnColor),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ListingIconFallback extends StatelessWidget {
  const _ListingIconFallback({required this.meta});
  final _CategoryMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      color: meta.color.withValues(alpha: 0.15),
      child: Icon(meta.icon, color: meta.color, size: 26),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({
    required this.message,
    required this.showClearFilter,
    required this.clearLabel,
    required this.onClear,
  });
  final String message;
  final bool showClearFilter;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 32, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          if (showClearFilter) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onClear,
              child: Text(clearLabel, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('select_category_error'))),
      );
      return;
    }
    final seller = ref.read(currentUserProvider).valueOrNull?.name;
    if (seller == null) return;

    setState(() => _saving = true);
    await ref.read(marketplaceDaoProvider).addListing(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory!,
          sellerName: seller,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          imagePath: _imagePath,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = ref.watch(currentUserProvider).valueOrNull?.name ?? '…';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(_t('list_product_btn'), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${_t('listing_as')} $sellerName',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickingImage ? null : _pickImage,
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.cardOverlay.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickingImage
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _imagePath != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    Positioned(
                                      top: 4, right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imagePath = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: _t('listing_title_hint')),
                  validator: (v) => (v == null || v.trim().isEmpty) ? _t('listing_title_error') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: _t('listing_price_hint')),
                  validator: (v) {
                    final parsed = double.tryParse((v ?? '').trim());
                    return (parsed == null || parsed <= 0) ? _t('listing_price_error') : null;
                  },
                ),
                const SizedBox(height: 12),
                Text(_t('select_category_label'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryMeta.map((c) {
                    final isSelected = _selectedCategory == c.key;
                    return ChoiceChip(
                      label: Text(_t(c.labelKey)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = c.key),
                      selectedColor: c.color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: isSelected ? c.color : AppColors.textSecondary, fontWeight: FontWeight.w600),
                      side: BorderSide(color: isSelected ? c.color : AppColors.border),
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
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
