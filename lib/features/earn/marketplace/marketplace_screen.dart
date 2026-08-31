import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import '../../../shared/widgets/market/market_category_card.dart';
import '../../../shared/widgets/market/market_empty_listings.dart';
import '../../../shared/widgets/market/market_header_bar.dart';
import '../../../shared/widgets/market/market_hero_card.dart';
import '../../../shared/widgets/market/market_listing_card.dart';
import '../../../shared/widgets/market/market_section_header.dart';
import '../../../shared/widgets/market/market_ui.dart';
import '../../../shared/widgets/messaging/chat_room_screen.dart';

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
    color: Color(0xFF5BB8E8),
  ),
  (
    key: 'crafts',
    labelKey: 'cat_crafts',
    icon: Icons.palette_outlined,
    color: Color(0xFF7EB8E8),
  ),
  (
    key: 'food_drink',
    labelKey: 'cat_food_drink',
    icon: Icons.restaurant_outlined,
    color: AppColors.primary,
  ),
  (
    key: 'fashion',
    labelKey: 'cat_fashion',
    icon: Icons.checkroom_outlined,
    color: Color(0xFF4A8FE8),
  ),
  (
    key: 'beauty',
    labelKey: 'cat_beauty',
    icon: Icons.spa_outlined,
    color: Color(0xFF3BAFD4),
  ),
  (
    key: 'services',
    labelKey: 'cat_services',
    icon: Icons.handyman_outlined,
    color: AppColors.online,
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
    final ui = MarketUi.of(context);
    String t(String key) => S.tr(context, ref, key);

    void openListingSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ui.card,
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.pageDecoration(context),
        child: SafeArea(
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
                      style: TextStyle(
                        fontSize: 13,
                        color: ui.textSecondary,
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
      children: _categoryMeta.map((c) {
        final isSelected = selected == c.key;
        return MarketCategoryCard(
          label: t(c.labelKey),
          icon: c.icon,
          accent: c.color,
          selected: isSelected,
          onTap: () =>
              ref.read(selectedMarketplaceCategoryProvider.notifier).state =
                  isSelected ? null : c.key,
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
      loading: () => const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: MarketUi.accent,
          ),
        ),
      ),
      error: (e, _) => Text(
        S.literal('Could not load listings'),
        style: TextStyle(fontSize: 13, color: MarketUi.of(context).textSecondary),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return MarketEmptyListings(
            title: hasFilter
                ? t('no_listings_in_category')
                : t('no_listings_yet'),
            subtitle: hasFilter
                ? t('browse_products')
                : S.literal('Be the first to list a product!'),
            ctaLabel: t('list_product_btn'),
            onCta: onAdd,
            showClearFilter: hasFilter,
            clearLabel: t('clear_filter'),
            onClear: () =>
                ref.read(selectedMarketplaceCategoryProvider.notifier).state =
                    null,
          );
        }
        return Column(
          children: listings.map((l) {
            final meta = _metaFor(l.category);
            final sellerLine = l.location != null
                ? '${l.sellerName} · ${l.location}'
                : l.sellerName;
            return MarketListingCard(
              title: l.title,
              sellerLine: sellerLine,
              priceLabel: _formatUgx(l.price),
              fallbackIcon: meta.icon,
              imagePath: l.imagePath,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: MarketUi.of(context).card,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (_) => _ListingDetailSheet(listing: l),
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('select_category_error'))),
      );
      return;
    }

    setState(() => _saving = true);
    // Await the real value instead of reading whatever's synchronously
    // available — currentUserProvider's stream may not have emitted its
    // first snapshot yet if this sheet is opened right after app start,
    // and reading a not-yet-loaded value here used to fail this whole
    // submit silently (no error, no listing) with zero feedback.
    final seller = (await ref.read(currentUserProvider.future))?.name;
    if (seller == null) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.literal('Could not find your profile. Please try again.'))),
        );
      }
      return;
    }

    await ref.read(marketplaceDaoProvider).addListing(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          category: _selectedCategory!,
          sellerName: seller,
          // Captured at listing time (E.164) so a buyer can message/call
          // the seller directly later — WhatsApp Business catalog-style,
          // not brokered through the app itself.
          sellerPhone: FirebaseAuth.instance.currentUser?.phoneNumber,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          imagePath: _imagePath,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = ref.watch(currentUserProvider).valueOrNull?.name ?? '…';
    final ui = MarketUi.of(context);

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
                      color: ui.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _t('list_product_btn'),
                  style: TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ui.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_t('listing_as')} $sellerName',
                  style: TextStyle(
                    fontSize: 13,
                    color: ui.textSecondary,
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
                        color: ui.iconWell,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ui.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickingImage
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
                                        onTap: () =>
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
                              : Icon(
                                  Icons.add_a_photo_outlined,
                                  color: ui.textSecondary,
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
                  validator: (v) => (v == null || v.trim().isEmpty)
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ui.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryMeta.map((c) {
                    final isSelected = _selectedCategory == c.key;
                    return ChoiceChip(
                      label: Text(_t(c.labelKey)),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = c.key),
                      selectedColor: c.color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color:
                            isSelected ? c.color : ui.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected ? c.color : ui.border,
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
                        borderRadius:
                            BorderRadius.circular(MarketUi.radiusBtn),
                      ),
                    ),
                    child: _saving
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

/// WhatsApp Business catalog-style contact step: the app never brokers the
/// sale itself (no checkout, no payment processing) — it just gets the
/// buyer and seller talking, exactly how commerce already happens for this
/// audience via mobile money arranged over a direct chat.
class _ListingDetailSheet extends ConsumerWidget {
  const _ListingDetailSheet({required this.listing});
  final MarketplaceListing listing;

  Future<void> _messageOnWhatsApp(
    BuildContext context,
    String Function(String key) t,
  ) async {
    final phone = listing.sellerPhone;
    if (phone == null) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message =
        '${t('whatsapp_interest_message')} ${listing.title} - ${_formatUgx(listing.price)}';
    await launchUrl(
      Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callSeller() async {
    final phone = listing.sellerPhone;
    if (phone == null) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  /// Opens (or resumes) a persisted in-app chat with the seller instead of
  /// deep-linking out to WhatsApp — keeps the conversation, and the user,
  /// on the platform.
  Future<void> _chatOnPlatform(BuildContext context, WidgetRef ref) async {
    final conversationId = await ref.read(messagingDaoProvider).getOrCreateConversation(
          type: 'marketplace',
          subjectId: listing.id,
          title: listing.title,
          counterpartName: listing.sellerName,
        );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatRoomScreen(conversationId: conversationId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final ui = MarketUi.of(context);
    String t(String key) => S.tr(context, ref, key);
    final meta = _metaFor(listing.category);
    final hasContact = listing.sellerPhone != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                    color: ui.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: listing.imagePath != null
                      ? Image.file(
                          File(listing.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _DetailImageFallback(icon: meta.icon),
                        )
                      : _DetailImageFallback(icon: meta.icon),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                listing.title,
                style: TextStyle(
                  fontFamily: 'Saira',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ui.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatUgx(listing.price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MarketUi.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listing.location != null
                    ? '${t('sold_by')} ${listing.sellerName} · ${listing.location}'
                    : '${t('sold_by')} ${listing.sellerName}',
                style: TextStyle(fontSize: 13, color: ui.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _chatOnPlatform(context, ref),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text(t('chat_on_platform')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MarketUi.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MarketUi.radiusBtn),
                    ),
                  ),
                ),
              ),
              if (hasContact) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _messageOnWhatsApp(context, t),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(t('message_on_whatsapp')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MarketUi.radiusBtn),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _callSeller,
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(t('call_seller')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ui.textPrimary,
                      side: BorderSide(color: ui.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MarketUi.radiusBtn),
                      ),
                    ),
                  ),
                ),
              ] else
                Text(
                  t('no_contact_available'),
                  style: TextStyle(fontSize: 13, color: ui.textSecondary),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  label: Text(
                    S.literal('Delete this listing'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.literal('Delete this listing?')),
        content: Text(S.literal("It will be removed from the marketplace. This can't be undone.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.literal('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.literal('Delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(marketplaceDaoProvider).deleteListing(listing.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _DetailImageFallback extends StatelessWidget {
  const _DetailImageFallback({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MarketUi.of(context).iconWell,
      child: Icon(icon, color: MarketUi.accent, size: 40),
    );
  }
}
