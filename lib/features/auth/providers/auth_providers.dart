import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Set synchronously at startup (mirrors `hasProfileProvider`) from
/// `authStateChanges().first`, awaited before `runApp`.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Stashed between the phone-entry and OTP-verify screens.
final verificationIdProvider = StateProvider<String?>((ref) => null);
final pendingPhoneNumberProvider = StateProvider<String?>((ref) => null);
