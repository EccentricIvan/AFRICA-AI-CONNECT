import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final loadingLocale = ref.watch(localeLoadingProvider);

    return Semantics(
      button: true,
      label: 'Change language',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              loadingLocale == null
                  ? () => _showLanguageSheet(context, ref)
                  : null,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loadingLocale != null)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    locale.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<AppLocale>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, sheetRef, child) {
            final currentLocale = sheetRef.watch(localeProvider);
            final loadingLocale = sheetRef.watch(localeLoadingProvider);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.language_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          S.tr(context, sheetRef, 'choose_language'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (final option in AppLocale.values)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      selected: currentLocale == option,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      title: Text(
                        option.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing:
                          loadingLocale == option
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : currentLocale == option
                              ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                              )
                              : null,
                      onTap:
                          loadingLocale == null
                              ? () => Navigator.pop(sheetContext, option)
                              : null,
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null || !context.mounted) return;

    final changed = await selectAppLocale(ref, selected);

    if (!changed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load this language. Check your connection and try again.',
          ),
        ),
      );
    }
  }
}
