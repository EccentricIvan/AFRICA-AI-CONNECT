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
  final initialLocale = LocaleNotifier.fromSaved(savedLocale);
  await S.loadBundledTranslations();

  runApp(
    ProviderScope(
      overrides: [
        isAuthenticatedProvider.overrideWith((ref) => firebaseUser != null),
        hasProfileProvider.overrideWith((ref) => hasProfile),
        localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
      ],
      child: const AfricaAiConnectApp(),
    ),
  );
}
