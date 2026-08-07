import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../db/providers/database_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  final _nameController = TextEditingController();
  String? _role;
  String? _location;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _t(String key) => S.tr(context, ref, key);

  void _next() {
    if (_page == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('please_enter_name'))));
      return;
    }
    if (_page < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    if (firebaseUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
            'name': name,
            'role': _role,
            'location': _location,
            'phoneNumber': firebaseUser.phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
    await ref
        .read(userDaoProvider)
        .saveUser(
          name: name,
          role: _role,
          location: _location,
          firebaseUid: firebaseUser?.uid,
        );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_profile', true);
    ref.read(hasProfileProvider.notifier).state = true;
    if (mounted) context.go('/');
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _page == i
                                ? AppColors.primary
                                : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _LanguagePage(ref: ref),
                    _WelcomePage(controller: _nameController, t: _t),
                    _RolePage(
                      selected: _role,
                      location: _location,
                      onRole: (r) => setState(() => _role = r),
                      onLocation: (l) => setState(() => _location = l),
                      t: _t,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  children: [
                    if (_page > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          child: Text(_t('back')),
                        ),
                      ),
                    if (_page > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _next,
                        child:
                            _saving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  _page < 2
                                      ? _t('continue_btn')
                                      : _t('start_journey'),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 12),
          Image.asset(
            'assets/branding/app_icon_mark.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose your language',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Londa olulimi lwo · Chagua lugha yako',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ...AppLocale.values.map((locale) {
            final isSelected = currentLocale == locale;
            return GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).set(locale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : const Color(0x123A2E29),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primary
                            : const Color(0x223A2E29),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.label,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale.shortCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x443A2E29),
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.controller, required this.t});
  final TextEditingController controller;
  final String Function(String) t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const SizedBox(height: 12),
          Image.asset(
            'assets/branding/app_icon_mark.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            t('welcome_to'),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 10),
          Text(
            t('welcome_desc'),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            t('whats_your_name'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: t('enter_your_name'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePage extends StatelessWidget {
  const _RolePage({
    required this.selected,
    required this.location,
    required this.onRole,
    required this.onLocation,
    required this.t,
  });
  final String? selected;
  final String? location;
  final void Function(String?) onRole;
  final void Function(String?) onLocation;
  final String Function(String) t;

  List<(String, String, IconData, String)> get _roles => [
    (
      'role_entrepreneur',
      'role_entrepreneur_desc',
      Icons.rocket_launch,
      'Entrepreneur',
    ),
    ('role_farmer', 'role_farmer_desc', Icons.agriculture, 'Farmer'),
    ('role_student', 'role_student_desc', Icons.school, 'Student'),
    (
      'role_job_seeker',
      'role_job_seeker_desc',
      Icons.work_outline,
      'Job Seeker',
    ),
    ('role_leader', 'role_leader_desc', Icons.groups, 'Community Leader'),
    ('role_artisan', 'role_artisan_desc', Icons.palette, 'Artisan / Creator'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            t('about_you'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            t('about_you_desc'),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t('what_describes_you'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._roles.map((r) {
            final isSelected = selected == r.$4;
            return GestureDetector(
              onTap: () => onRole(selected == r.$4 ? null : r.$4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.primary
                            : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      r.$3,
                      color:
                          isSelected
                              ? AppColors.primary
                              : Theme.of(context).hintColor,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(r.$1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            t(r.$2),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(t('where_based'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            onChanged: onLocation,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: t('location_hint'),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
