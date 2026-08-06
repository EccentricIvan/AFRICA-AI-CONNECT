import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import 'providers/auth_providers.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  String _t(String key) => S.tr(context, ref, key);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final digits = _controller.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      setState(() => _error = _t('invalid_phone_number'));
      return;
    }
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    final phoneNumber = '+256$local';

    setState(() {
      _sending = true;
      _error = null;
    });

    await ref.read(firebaseAuthServiceProvider).verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onAutoVerified: (credential) {
        if (!mounted) return;
        ref.read(isAuthenticatedProvider.notifier).state = true;
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = e.message ?? _t('otp_send_failed');
        });
      },
      onCodeSent: (verificationId) {
        ref.read(verificationIdProvider.notifier).state = verificationId;
        ref.read(pendingPhoneNumberProvider.notifier).state = phoneNumber;
        if (!mounted) return;
        setState(() => _sending = false);
        context.push('/auth/otp');
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
                  _t('enter_phone_number'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  onSubmitted: (_) => _sendCode(),
                  decoration: InputDecoration(
                    hintText: _t('phone_number_hint'),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '+256',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
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
                    onPressed: _sending ? null : _sendCode,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_t('send_code')),
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
