import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'db/providers/database_provider.dart';

class AfricaAiConnectApp extends ConsumerWidget {
  const AfricaAiConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Fire-and-forget: content-pack sync + history pruning. Watching (not
    // awaiting) means this never delays first paint — see
    // chatBootstrapProvider's doc comment.
    ref.watch(chatBootstrapProvider);
    ref.watch(settingsBootstrapProvider);
    return MaterialApp.router(
      title: 'AI Connect Africa',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
