import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Thin wrapper around FirebaseAuth's phone-verification flow.
class FirebaseAuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  fb.User? get currentUser => _auth.currentUser;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(fb.UserCredential credential) onAutoVerified,
    required void Function(fb.FirebaseAuthException e) onFailed,
    required void Function(String verificationId) onCodeSent,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        final userCredential = await _auth.signInWithCredential(credential);
        onAutoVerified(userCredential);
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<fb.UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}
