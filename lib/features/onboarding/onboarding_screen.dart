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
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ac.bgTop, ac.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = _page == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : const Color(0xFFE5D8CF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _LanguagePage(ref: ref),
                    _WelcomePage(
                      controller: _nameController,
                      t: _t,
                      saving: _saving,
                      onBack: _back,
                      onContinue: _next,
                    ),
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
              if (_page != 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (_page > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _back,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _t('back'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_page > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: _page == 0 ? 1 : 2,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _next,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _page < 2
                                                ? _t('continue_btn')
                                                : _t('start_journey'),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (_page == 0) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Secure. Private. Built for you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: ac.textHint,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// Presentational only — maps each locale to a Material icon + tint for the
/// language card tile. Does not affect selection, persistence, or localization.
class _LanguageVisual {
  const _LanguageVisual({
    required this.icon,
    required this.iconColor,
    required this.tileColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color tileColor;
}

const _languageVisuals = <AppLocale, _LanguageVisual>{
  AppLocale.en: _LanguageVisual(
    icon: Icons.public_rounded,
    iconColor: Color(0xFFC96F4A),
    tileColor: Color(0xFFF6E4DA),
  ),
  AppLocale.lg: _LanguageVisual(
    icon: Icons.eco_rounded,
    iconColor: Color(0xFF5E8C4A),
    tileColor: Color(0xFFE4F0DE),
  ),
  AppLocale.sw: _LanguageVisual(
    icon: Icons.water_rounded,
    iconColor: Color(0xFF7C5CBF),
    tileColor: Color(0xFFEBE4F5),
  ),
  AppLocale.nyn: _LanguageVisual(
    icon: Icons.terrain_rounded,
    iconColor: Color(0xFF9A6B4F),
    tileColor: Color(0xFFF0E6DE),
  ),
  AppLocale.teo: _LanguageVisual(
    icon: Icons.wb_sunny_rounded,
    iconColor: Color(0xFFD4A24E),
    tileColor: Color(0xFFF8F0DC),
  ),
  AppLocale.nyo: _LanguageVisual(
    icon: Icons.water_drop_rounded,
    iconColor: Color(0xFF5B8AA8),
    tileColor: Color(0xFFE0EDF4),
  ),
  AppLocale.ach: _LanguageVisual(
    icon: Icons.spa_rounded,
    iconColor: Color(0xFFB4436C),
    tileColor: Color(0xFFF4E0E8),
  ),
};

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final currentLocale = ref.watch(localeProvider);
    final heading = S.tr(context, ref, 'choose_language');
    final brandName = S.tr(context, ref, 'app_name');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        physics: const BouncingScrollPhysics(),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/branding/app_icon_mark.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  brandName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Saira',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Saira',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: ac.textHint,
                height: 1.45,
              ),
              children: const [
                TextSpan(text: 'Londa olulimi lwo '),
                TextSpan(
                  text: '•',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' Chagua lugha yako'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...AppLocale.values.map((locale) {
            final isSelected = currentLocale == locale;
            final visual = _languageVisuals[locale]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(localeProvider.notifier).set(locale),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 68),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : ac.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : ac.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ac.textPrimary.withValues(
                            alpha: isSelected ? 0.06 : 0.03,
                          ),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: visual.tileColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            visual.icon,
                            color: visual.iconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                locale.label,
                                style: TextStyle(
                                  fontFamily: 'Saira',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: ac.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                locale.shortCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ac.textHint,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFD9CFC8),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 15,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage({
    required this.controller,
    required this.t,
    required this.saving,
    required this.onBack,
    required this.onContinue,
  });
  final TextEditingController controller;
  final String Function(String) t;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  (String companion, String offline) _splitWelcomeDesc(String full) {
    final markers = [
      'Works online and offline',
      'Akola ku mutimbagano',
      'Inafanya kazi mtandaoni',
    ];
    for (final marker in markers) {
      final idx = full.indexOf(marker);
      if (idx > 0) {
        return (full.substring(0, idx).trim(), full.substring(idx).trim());
      }
    }
    final parts = full.split(RegExp(r'(?<=\.)\s+'));
    if (parts.length >= 2) {
      return (parts.first.trim(), parts.sublist(1).join(' ').trim());
    }
    return (full, full);
  }

  List<InlineSpan> _titleSpans(BuildContext context, String title,
      {required double fontSize}) {
    final base = TextStyle(
      fontFamily: 'Saira',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.of(context).textPrimary,
      height: 1.15,
      letterSpacing: -0.3,
    );
    final accent = TextStyle(
      fontFamily: 'Saira',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      height: 1.15,
      letterSpacing: -0.3,
    );
    final spans = <InlineSpan>[];
    var remaining = title;
    while (remaining.isNotEmpty) {
      final ai = remaining.indexOf('AI');
      if (ai < 0) {
        spans.add(TextSpan(text: remaining, style: base));
        break;
      }
      if (ai > 0) {
        spans.add(TextSpan(text: remaining.substring(0, ai), style: base));
      }
      spans.add(TextSpan(text: 'AI', style: accent));
      remaining = remaining.substring(ai + 2);
    }
    return spans;
  }

  Widget _heroIllustration() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 0.92,
            heightFactor: 0.72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8C4D8).withValues(alpha: 0.40),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            'assets/branding/welcome_hero.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          child: _FloatingIconCard(
            icon: Icons.school_rounded,
            color: AppColors.primary,
          ),
        ),
        const Positioned(
          top: 36,
          right: 0,
          child: _FloatingIconCard(
            icon: Icons.work_outline_rounded,
            color: AppColors.learnColor,
          ),
        ),
        const Positioned(
          bottom: 28,
          left: 0,
          child: _FloatingIconCard(
            icon: Icons.show_chart_rounded,
            color: AppColors.agricultureColor,
          ),
        ),
      ],
    );
  }

  Widget _offlineCard(String offlineDesc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3E4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF5E8C4A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              offlineDesc,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3F6B36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameCard(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ac.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('whats_your_name'),
                      style: TextStyle(
                        fontFamily: 'Saira',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ac.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.literal("Let's get to know you."),
                      style: TextStyle(
                        fontSize: 13,
                        color: ac.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: t('enter_your_name'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    final locale = ref.watch(localeProvider);
    final (companionDesc, offlineDesc) = _splitWelcomeDesc(t('welcome_desc'));
    final size = MediaQuery.sizeOf(context);
    final tall = size.height > 800;
    final compact = size.height < 700;
    final titleSize = compact ? 24.0 : tall ? 28.0 : 26.0;
    final gapAfterHeader = compact ? 12.0 : tall ? 18.0 : 16.0;
    final gapAfterHero = compact ? 20.0 : tall ? 32.0 : 28.0;
    final gapAfterOffline = compact ? 16.0 : tall ? 22.0 : 20.0;
    final heroFlex = tall ? 11 : 10;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: size.width * 0.28,
          top: size.height * 0.42,
          bottom: 0,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ac.bgBottom.withValues(alpha: 0),
                    const Color(0xFFE8C4D8).withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _WelcomeCurvesPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: compact ? 4 : 8),
                Row(
                  children: [
                    Image.asset(
                      'assets/branding/app_icon_mark.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    _WelcomeLanguageChip(locale: locale),
                  ],
                ),
                SizedBox(height: gapAfterHeader),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: _titleSpans(
                                context,
                                t('welcome_to'),
                                fontSize: titleSize,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 34,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            companionDesc,
                            style: TextStyle(
                              fontSize: compact ? 13 : 13.5,
                              height: 1.45,
                              color: ac.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: heroFlex,
                      child: AspectRatio(
                        aspectRatio: 0.78,
                        child: Transform.scale(
                          scale: tall ? 1.14 : 1.10,
                          alignment: Alignment.bottomCenter,
                          child: _heroIllustration(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gapAfterHero),
                _offlineCard(offlineDesc),
                SizedBox(height: gapAfterOffline),
                _nameCard(context),
                SizedBox(height: compact ? 20.0 : 22.0),
                _WelcomeFeatureStrip(narrow: size.width < 360),
                SizedBox(height: compact ? 20.0 : 24.0),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                t('back'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: saving ? null : onContinue,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      t('continue_btn'),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: ac.textHint,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        S.literal('Your data is secure with us.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: ac.textHint,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeFeatureStrip extends StatelessWidget {
  const _WelcomeFeatureStrip({required this.narrow});
  final bool narrow;

  static const _features = <({
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    Color tint,
  })>[
    (
      icon: Icons.school_rounded,
      title: 'Learn AI',
      subtitle: 'Courses & skills',
      accent: AppColors.primary,
      tint: Color(0xFFF6E4DA),
    ),
    (
      icon: Icons.work_outline_rounded,
      title: 'Earn',
      subtitle: 'Find opportunities',
      accent: AppColors.learnColor,
      tint: Color(0xFFEBE4F5),
    ),
    (
      icon: Icons.show_chart_rounded,
      title: 'Grow',
      subtitle: 'Build your future',
      accent: AppColors.agricultureColor,
      tint: Color(0xFFE4F0DE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final feature in _features)
        _WelcomeFeatureCard(
          icon: feature.icon,
          title: feature.title,
          subtitle: feature.subtitle,
          accent: feature.accent,
          tint: feature.tint,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you can do',
          style: TextStyle(
            fontFamily: 'Saira',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (narrow)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final card in cards)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48 - 12) / 2,
                  child: card,
                ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          ),
      ],
    );
  }
}

class _WelcomeFeatureCard extends StatelessWidget {
  const _WelcomeFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ac.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Saira',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ac.textHint,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeLanguageChip extends ConsumerWidget {
  const _WelcomeLanguageChip({required this.locale});
  final AppLocale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = AppColors.of(context);
    return Material(
      color: ac.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () async {
          final box = context.findRenderObject() as RenderBox?;
          final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
          final size = box?.size ?? Size.zero;
          final selected = await showMenu<AppLocale>(
            context: context,
            position: RelativeRect.fromLTRB(
              offset.dx,
              offset.dy + size.height + 4,
              24,
              0,
            ),
            items: [
              for (final option in AppLocale.values)
                PopupMenuItem(value: option, child: Text(option.label)),
            ],
          );
          if (selected != null) {
            ref.read(localeProvider.notifier).set(selected);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ac.surface,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: ac.textPrimary.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 16,
                color: ac.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                locale.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ac.textPrimary,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: ac.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingIconCard extends StatelessWidget {
  const _FloatingIconCard({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _WelcomeCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final paint = Paint()
        ..color =
            const Color(0xFFE5D8CF).withValues(alpha: 0.48 * (1 - t * 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15;
      final path = Path()
        ..moveTo(0, size.height * (0.05 + i * 0.13))
        ..quadraticBezierTo(
          size.width * 0.48,
          size.height * (0.0 + i * 0.12),
          size.width,
          size.height * (0.16 + i * 0.13),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
