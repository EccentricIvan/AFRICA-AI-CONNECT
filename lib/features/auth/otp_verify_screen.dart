import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../db/providers/database_provider.dart';
import 'providers/auth_providers.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  String _t(String key) => S.tr(context, ref, key);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length < 6) {
      setState(() => _error = _t('invalid_otp_code'));
      return;
    }
    final verificationId = ref.read(verificationIdProvider);
    if (verificationId == null) {
      setState(() => _error = _t('otp_verify_failed'));
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final credential =
          await ref.read(firebaseAuthServiceProvider).signInWithSmsCode(
                verificationId: verificationId,
                smsCode: code,
              );
      await _reconcileProfile(credential.user!.uid);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = _t('otp_verify_failed');
      });
    }
  }

  Future<void> _reconcileProfile(String uid) async {
    final firestoreDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await firestoreDoc.get();
    final userDao = ref.read(userDaoProvider);
    final prefs = await SharedPreferences.getInstance();

    if (doc.exists) {
      final d = doc.data()!;
      await userDao.saveUser(
        name: d['name'] as String? ?? '',
        role: d['role'] as String?,
        location: d['location'] as String?,
        firebaseUid: uid,
      );
      await prefs.setBool('has_profile', true);
      ref.read(hasProfileProvider.notifier).state = true;
    } else {
      // Edge case: local profile already exists from the pre-Firebase
      // Drift-only onboarding flow. Push it up instead of re-collecting it.
      final localUser = await userDao.watchUser().first;
      if (localUser != null) {
        await firestoreDoc.set({
          'name': localUser.name,
          'role': localUser.role,
          'location': localUser.location,
          'phoneNumber':
              ref.read(firebaseAuthServiceProvider).currentUser?.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await userDao.saveUser(
          name: localUser.name,
          role: localUser.role,
          location: localUser.location,
          firebaseUid: uid,
        );
        await prefs.setBool('has_profile', true);
        ref.read(hasProfileProvider.notifier).state = true;
      }
    }

    ref.read(isAuthenticatedProvider.notifier).state = true;
    if (!mounted) return;
    context.go(ref.read(hasProfileProvider) ? '/' : '/onboarding');
  }

  Future<void> _resend() async {
    final phoneNumber = ref.read(pendingPhoneNumberProvider);
    if (phoneNumber == null || _resending) return;
    setState(() => _resending = true);
    await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onAutoVerified: (credential) {
        if (!mounted) return;
        ref.read(isAuthenticatedProvider.notifier).state = true;
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _resending = false;
          _error = e.message ?? _t('otp_send_failed');
        });
      },
      onCodeSent: (verificationId) {
        ref.read(verificationIdProvider.notifier).state = verificationId;
        if (!mounted) return;
        setState(() => _resending = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/app_icon_mark.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  _t('enter_otp_code'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t('windows_recaptcha_note'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    hintText: _t('otp_code_hint'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    child: _verifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_t('verify_code')),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_t('resend_code')),
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
