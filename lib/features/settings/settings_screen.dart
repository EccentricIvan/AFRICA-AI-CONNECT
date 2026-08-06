import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/l10n/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

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
                      onChanged:
                          (mode) =>
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
                          leading: Text(
                            l.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(l.label),
                          subtitle: Text(l.shortCode),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 22,
                                  )
                                  : null,
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          onTap: () => ref.read(localeProvider.notifier).set(l),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('data_sync'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.cloud_sync),
                      title: const Text('Auto-sync when online'),
                      subtitle: const Text('Sync your progress when connected'),
                      value: true,
                      onChanged: (v) {},
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text('Download content for offline'),
                        subtitle: const Text('Last synced: Today'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.storage),
                        title: const Text('Storage usage'),
                        subtitle: const Text('45 MB used'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('notifications'),
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications),
                      title: const Text('Push notifications'),
                      subtitle: const Text(
                        'Get updates on opportunities and community',
                      ),
                      value: true,
                      onChanged: (v) {},
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.campaign),
                      title: const Text('Community updates'),
                      subtitle: const Text(
                        'Posts and activity from your groups',
                      ),
                      value: true,
                      onChanged: (v) {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: t('about'),
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Africa AI Connect'),
                      subtitle: Text('Version 1.0.0'),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () {},
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () {},
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
  const _SettingsSection({required this.title, required this.children});
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
        Card(child: Column(children: children)),
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
      title: const Text('Theme'),
      subtitle: Text(
        currentMode == ThemeMode.dark
            ? 'Dark'
            : currentMode == ThemeMode.light
            ? 'Light'
            : 'System',
      ),
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
