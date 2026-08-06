import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/phone_entry_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/learn_hub_screen.dart';
import '../../features/earn/marketplace/marketplace_screen.dart';
import '../../features/earn/financial/financial_hub_screen.dart';
import '../../features/grow/mentorship/mentorship_screen.dart';
import '../../features/grow/jobs/jobs_screen.dart';
import '../../features/grow/skills/skills_screen.dart';
import '../../features/thrive/health/health_screen.dart';
import '../../features/thrive/community/community_screen.dart';
import '../../features/thrive/wellbeing/wellbeing_screen.dart';
import '../../features/ai_chat/ai_chat_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final hasProfileProvider = StateProvider<bool>((ref) {
  // Synchronous — reads SharedPreferences at startup via the notifier
  return false;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // Phone auth isn't live yet (Firebase project isn't on Blaze), so startup
  // routing doesn't gate on isAuthenticatedProvider — /auth/phone and
  // /auth/otp stay reachable for later, but don't block anyone today.
  final hasProfile = ref.watch(hasProfileProvider);
  final initialLocation = hasProfile ? '/' : '/onboarding';
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/auth/phone',
        builder: (_, __) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, __) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ── Core tabs ──
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/learn', builder: (_, __) => const LearnHubScreen()),
          GoRoute(
              path: '/marketplace',
              builder: (_, __) => const MarketplaceScreen()),
          GoRoute(
              path: '/community',
              builder: (_, __) => const CommunityScreen()),

          // ── Earn pillar ──
          GoRoute(
              path: '/financial',
              builder: (_, __) => const FinancialHubScreen()),

          // ── Grow pillar ──
          GoRoute(
              path: '/mentorship',
              builder: (_, __) => const MentorshipScreen()),
          GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
          GoRoute(
              path: '/skills', builder: (_, __) => const SkillsScreen()),

          // ── Thrive pillar ──
          GoRoute(
              path: '/health', builder: (_, __) => const HealthScreen()),
          GoRoute(
              path: '/wellbeing',
              builder: (_, __) => const WellbeingScreen()),

          // ── Tools ──
          GoRoute(
              path: '/ai-chat', builder: (_, __) => const AiChatScreen()),
          GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
