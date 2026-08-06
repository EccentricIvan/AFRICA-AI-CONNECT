import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_strings.dart';
import 'features/auth/providers/auth_providers.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firebaseUser = await FirebaseAuth.instance.authStateChanges().first;

  final prefs = await SharedPreferences.getInstance();
  final hasProfile = prefs.getBool('has_profile') ?? false;
  final savedLocale = prefs.getString('app_locale');

  runApp(
    ProviderScope(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => firebaseUser != null),
        hasProfileProvider.overrideWith((ref) => hasProfile),
      ],
      child: _LocaleLoader(savedLocale: savedLocale),
    ),
  );
}

class _LocaleLoader extends ConsumerStatefulWidget {
  const _LocaleLoader({this.savedLocale});
  final String? savedLocale;

  @override
  ConsumerState<_LocaleLoader> createState() => _LocaleLoaderState();
}

class _LocaleLoaderState extends ConsumerState<_LocaleLoader> {
  @override
  void initState() {
    super.initState();
    if (widget.savedLocale != null) {
      ref.read(localeProvider.notifier).loadFromPrefs(widget.savedLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AfricaAiConnectApp();
  }
}
