import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../db/providers/database_provider.dart';
import '../auth/providers/auth_providers.dart';
import 'legal_info_screen.dart';

/// Sums the on-disk size of the local SQLite database and every saved
/// image folder — a real number instead of a hardcoded "45 MB used".
final storageUsageBytesProvider = FutureProvider<int>((ref) async {
  final docsDir = await getApplicationDocumentsDirectory();
  var total = 0;
  for (final name in [
    'otic_connect.sqlite',
    'otic_connect.sqlite-wal',
    'otic_connect.sqlite-shm',
  ]) {
    final file = File(p.join(docsDir.path, name));
    if (await file.exists()) total += await file.length();
  }
  for (final sub in [
    'profile_photos',
    'community_group_photos',
    'marketplace_photos',
  ]) {
    final dir = Directory(p.join(docsDir.path, sub));
    if (!await dir.exists()) continue;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
  }
  return total;
});

String _formatBytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  if (mb < 0.1) return '< 0.1 MB';
  return '${mb.toStringAsFixed(1)} MB';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.literal('Sign out?')),
        content: Text(S.literal(
          'This clears your profile, listings, messages, and progress from this device. Make sure anything important is backed up first.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.literal('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.literal('Sign out')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(firebaseAuthServiceProvider).signOut();
    await ref.read(appDatabaseProvider).clearAllLocalData();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_profile', false);

    ref.read(hasProfileProvider.notifier).state = false;
    ref.read(isAuthenticatedProvider.notifier).state = false;

    if (context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final loadingLocale = ref.watch(localeLoadingProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final storageAsync = ref.watch(storageUsageBytesProvider);

    String t(String key) => S.tr(context, ref, key);

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSection(
                  title: t('appearance'),
                  children: [
                    _ThemeTile(
                      currentMode: themeMode,
                      onChanged: (mode) =>
                          ref.read(themeModeProvider.notifier).set(mode),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('language'),
                  children: [
                    ...AppLocale.values.map((l) {
                      final isSelected = locale == l;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(l.label),
                          subtitle: Text(l.code),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                              : loadingLocale == l
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                              : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                          onTap: loadingLocale != null
                              ? null
                              : () async {
                                  final ok = await selectAppLocale(ref, l);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.literal('Could not download this language. Check your internet and try again.'),
                                        ),
                                      ),
                                    );
                                  }
                                },
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('data_sync'),
                  children: [
                    settingsAsync.when(
                      loading: () => const SwitchListTile(
                        secondary: Icon(Icons.cloud_sync),
                        title: Text('Auto-sync when online'),
                        value: true,
                        onChanged: null,
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (settings) => SwitchListTile(
                        secondary: const Icon(Icons.cloud_sync),
                        title: Text(S.literal('Auto-sync when online')),
                        subtitle: Text(S.literal('Sync your progress when connected')),
                        value: settings.autoSyncEnabled,
                        onChanged: (v) =>
                            ref.read(settingsDaoProvider).setAutoSync(v),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.download_done),
                        title: Text(S.literal('Offline content')),
                        subtitle: Text(S.literal('All app content is bundled with the app — nothing to download')),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(S.literal(
                              'This app works fully offline already — every language and knowledge-base file ships inside the app.',
                            )),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.storage),
                        title: Text(S.literal('Storage usage')),
                        subtitle: Text(storageAsync.when(
                          data: (bytes) => S.literal('${_formatBytes(bytes)} used'),
                          loading: () => S.literal('Calculating…'),
                          error: (_, __) => S.literal('Unavailable'),
                        )),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref.invalidate(storageUsageBytesProvider),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('notifications'),
                  children: [
                    settingsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (settings) => Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications),
                            title: Text(S.literal('Push notifications')),
                            subtitle: Text(S.literal('Get updates on opportunities and community')),
                            value: settings.pushNotificationsEnabled,
                            onChanged: (v) => ref
                                .read(settingsDaoProvider)
                                .setPushNotifications(v),
                          ),
                          SwitchListTile(
                            secondary: const Icon(Icons.campaign),
                            title: Text(S.literal('Community updates')),
                            subtitle: Text(S.literal('Posts and activity from your groups')),
                            value: settings.communityUpdatesEnabled,
                            onChanged: (v) => ref
                                .read(settingsDaoProvider)
                                .setCommunityUpdates(v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: S.literal('Account'),
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          S.literal('Sign out'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        subtitle: Text(S.literal('Clears this device\'s local data')),
                        onTap: () => _signOut(context, ref),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('about'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(S.literal('AI Connect Africa')),
                      subtitle: Text(S.literal('Version 1.0.0')),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(S.literal('Terms of Service')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LegalInfoScreen(
                              title: S.literal('Terms of Service'),
                              body: LegalInfoScreen.termsBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: Text(S.literal('Privacy Policy')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LegalInfoScreen(
                              title: S.literal('Privacy Policy'),
                              body: LegalInfoScreen.privacyBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(
      {required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.primary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.currentMode, required this.onChanged});
  final ThemeMode currentMode;
  final void Function(ThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        currentMode == ThemeMode.dark
            ? Icons.dark_mode
            : currentMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.brightness_auto,
      ),
      title: Text(S.literal('Theme')),
      subtitle: Text(currentMode == ThemeMode.dark
          ? S.literal('Dark')
          : currentMode == ThemeMode.light
              ? S.literal('Light')
              : S.literal('System')),
      trailing: SegmentedButton<ThemeMode>(
        selected: {currentMode},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode, size: 16),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 16),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 16),
          ),
        ],
      ),
    );
  }
}
