import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/offline_language_service.dart';

enum AppLocale {
  en('English', 'EN'),
  lg('Luganda', 'LG'),
  sw('Kiswahili', 'SW'),
  nyn('Runyankore', 'NYN'),
  teo('Ateso', 'TEO'),
  nyo('Runyoro', 'NYO'),
  ach('Acholi', 'ACH'),
  rw('Kinyarwanda', 'RW');

  const AppLocale(this.label, this.code);
  final String label;
  final String code;

  static const activeLocales = [AppLocale.en, AppLocale.lg, AppLocale.sw];

  static AppLocale fromLanguageCode(String code) {
    for (final locale in activeLocales) {
      if (locale.name == code) return locale;
    }
    return AppLocale.en;
  }
}

final offlineLanguageServiceProvider =
    ChangeNotifierProvider<OfflineLanguageService>((ref) {
      return OfflineLanguageService.instance;
    });

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier(ref.read(offlineLanguageServiceProvider));
});

final localeLoadingProvider = StateProvider<AppLocale?>((ref) => null);

Future<bool> selectAppLocale(WidgetRef ref, AppLocale locale) async {
  final loadingNotifier = ref.read(localeLoadingProvider.notifier);
  final localeNotifier = ref.read(localeProvider.notifier);
  loadingNotifier.state = locale;
  try {
    await S.ensureBundle(locale);
    localeNotifier.set(locale);
    return true;
  } catch (_) {
    return false;
  } finally {
    loadingNotifier.state = null;
  }
}

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier(this._languageService)
    : super(AppLocale.fromLanguageCode(_languageService.currentLanguageCode));

  final OfflineLanguageService _languageService;

  Future<void> set(AppLocale locale) async {
    await _languageService.loadLanguage(locale.name);
    state = AppLocale.fromLanguageCode(_languageService.currentLanguageCode);
  }

  Future<void> loadFromPrefs(String? saved) async {
    if (saved == null) return;
    await _languageService.loadLanguage(saved);
    state = AppLocale.fromLanguageCode(_languageService.currentLanguageCode);
  }
}

class S {
  S._();

  static final Map<AppLocale, Map<String, String>> _downloaded = {};
  static AppLocale _activeLocale = AppLocale.en;

  static const _uiLiterals = <String>[
    'My Profile',
    'Friend',
    'My Progress',
    'Track your learning and growth',
    'Could not download this language. Check your internet and try again.',
    'Achievements',
    "Badges you've earned",
    'Member',
    'Location not set',
    'Courses',
    'Points',
    'Streak',
    'days',
    'Badges',
    'Digital Skills',
    'Financial Literacy',
    'Entrepreneurship',
    'First Step',
    'Quick Learner',
    'Community Star',
    'Entrepreneur',
    'Consistent',
    'Auto-sync when online',
    'Sync your progress when connected',
    'Download content for offline',
    'Last synced: Today',
    'Storage usage',
    '45 MB used',
    'Push notifications',
    'Get updates on opportunities and community',
    'Community updates',
    'Posts and activity from your groups',
    'Version 1.0.0',
    'Terms of Service',
    'Privacy Policy',
    'Theme',
    'Dark',
    'Light',
    'System',
    'Financial Hub',
    'Financial Tools',
    'Manage your money wisely',
    'Savings Tracker',
    'Set goals and track your savings progress',
    'Budget Planner',
    'Plan your income and expenses',
    'SACCO Directory',
    'Find savings groups and cooperatives near you',
    'Mobile Money Guide',
    'Learn to send, receive, and save with mobile money',
    'Build your money knowledge',
    'Take control of your finances',
    'Tools and resources to help you save, budget, and grow your money.',
    'Start Small',
    'Even saving 500 UGX a day adds up over time',
    'Track Expenses',
    'Know where your money goes each week',
    'Join a SACCO',
    'Group savings help you access loans and support',
    'Job Board',
    'Recent Opportunities',
    'Jobs and gigs near you',
    'Build Your CV',
    'Create a professional profile',
    'Find your next opportunity',
    'Browse jobs, freelance gigs, and training programmes from verified employers.',
    'Community Health Worker',
    'NGO Partner · Kampala',
    'Full-time',
    'Digital Marketing Assistant',
    'Tech Hub · Remote',
    'Part-time',
    'Agricultural Extension Officer',
    'District Gov · Mbale',
    'Contract',
    'Tailoring Trainer',
    "Women's Centre · Jinja",
    'CV Builder',
    'Create a professional CV that highlights your skills and experience. AI-assisted — just answer a few questions.',
    'Create CV',
    'Skills & Training',
    'Build future-ready skills',
    'Practical training programmes to boost your career and business.',
    'Training Programmes',
    'Upskill with structured courses',
    'Digital Literacy',
    'Phone, internet, and computer basics',
    'Business Management',
    'Planning, accounting, and operations',
    'Value Addition',
    'Processing, packaging, and branding products',
    'Communication Skills',
    'Negotiation, presentation, and networking',
    'Your Groups',
    'Communities you belong to',
    'Discover Groups',
    "Join women's groups in your area",
    'Community Feed',
    'Latest from women in your network',
    'Stronger together',
    "Connect with women's groups, share experiences, support each other, and grow together.",
    'No groups yet',
    'Join a group below or create your own',
    'Create a Group',
    'Kampala Women Entrepreneurs',
    'members',
    'Digital Skills Network',
    'Farmers United',
    'Young Mothers Support',
    'Join',
    'Like',
    'Comment',
    'Share',
    'Just completed the Digital Skills course! So proud of this journey.',
    'My basket-weaving business got its first wholesale order today!',
    'Looking for women interested in forming a SACCO in Gulu district.',
    '2 hours ago',
    '5 hours ago',
    '1 day ago',
    'Your wellbeing matters',
    'Resources for self-care, emotional support, and building resilience.',
    'Self-Care',
    'Daily practices for a healthier mind',
    'Stress Management',
    'Techniques to manage daily stress and anxiety',
    'Positive Affirmations',
    'Daily encouragement and confidence building',
    'Support Resources',
    'Helplines, counselling, and safe spaces',
    'Safety & Support',
    'If you or someone you know needs help, trusted support is available.',
    'Get Help',
    'Uganda Police Emergency',
    'For immediate danger or a safety emergency',
    'Uganda Emergency Services (alt.)',
    'Alternate national emergency line',
    'Talk to someone you trust',
    "A family member, friend, or community leader can help you find local support even when a hotline isn't available.",
    'If you are in immediate danger, contact emergency services now.',
    // ── Added for Community/AI Chat/Learn/Profile coverage ──
    "Let's get to know you.",
    'Your data is secure with us.',
    'Connect. Learn. Grow.',
    'women across',
    'communities',
    'Create a Community',
    'Chats',
    'Feed',
    'Discover',
    'Search your communities',
    'No conversations found',
    'Search posts from your communities',
    'No posts found',
    'Communities',
    'Search groups to join',
    'No groups found',
    'Location',
    'Filter Communities',
    'Apply',
    'Joined',
    'Left',
    'Please choose a category',
    'Community created',
    'Group name',
    'Enter a group name',
    'What is this group about?',
    'Create Community',
    'Dismiss',
    'Created by',
    "You're a member",
    'Members',
    'Admin',
    'tap for details',
    'Message',
    'A place for women in this community to share opportunities, ask questions, and support one another.',
    "A place for women in this community to share opportunities, ask questions, and support one another's growth.",
    'Business',
    'Family & Support',
    'Fashion & Crafts',
    'Tailors & Textile Circle',
    'Savings Circle Kampala',
    'Anyone free for the Saturday market meet-up?',
    'Just shared the new tutorial link!',
    'Thanks everyone, see you at the training.',
    '12m',
    '2h',
    '1d',
    "Hey everyone, hope you're all doing well this week!",
    'Doing great, thanks for asking!',
    'Mentor',
    'Trader',
    'Volunteer',
    'Downloads',
    'Certificates',
    'Bookmarks',
    'Notes',
    'History',
    'Your Learning Progress',
    'Courses Completed',
    'Days Streak',
    'Points Earned',
    'Complete 2 more lessons to reach your next milestone',
    'Recommended',
    'Learning Journey',
    'Daily Insight',
    'Read more',
    'Quick Tools',
    'Keep learning.',
    'Keep growing.',
    "Hello, I'm your AI Assistant",
    'Explore popular topics',
    'Business\nAdvice',
    'Farming\nTips',
    'Health\nInfo',
    'Health tips for my family',
    'Finance\nGuidance',
    'More\nTopics',
    'Be the first to list a product!',
    'Could not load listings',
    'Offline guidance',
    'Completed Courses',
    'Communities Joined',
    'Badges Earned',
    'Your Streak Progress',
    'Ongoing Courses',
    "You're on fire!",
    'Best',
    'Edit Profile',
    'Your name',
    'Tell others a little about yourself',
    'I am a',
    'Save Changes',
    'Add a short bio to introduce yourself',
    'Add role',
    // ── Added for notifications, onboarding & progress-card coverage ──
    'New badge unlocked',
    'You earned "Quick Learner" for finishing 3 lessons this week.',
    '2m ago',
    'Community activity',
    'Grace replied in Kampala Women Entrepreneurs.',
    '25m ago',
    "Don't lose your streak",
    "You're 1 lesson away from a 7-day streak.",
    '3h ago',
    'New job match',
    'A "Digital Marketing Assistant" role matches your profile.',
    '1d ago',
    'Mentorship request',
    'Peace N. wants to connect with you as a mentee.',
    '2d ago',
    'Course update',
    'A new module was added to Digital Skills 101.',
    '4d ago',
    'Secure. Private. Built for you.',
    'Learn AI',
    'Courses & skills',
    'Find opportunities',
    'Build your future',
    'What you can do',
    'Keep learning',
    'Awesome progress!',
    'left',
    'Next 550',
    'Best: 12d',
  ];

  static String _apiCode(AppLocale locale) => switch (locale) {
    AppLocale.en => 'eng',
    AppLocale.lg => 'lug',
    AppLocale.sw => 'swa',
    AppLocale.nyn => 'nyn',
    AppLocale.teo => 'teo',
    AppLocale.nyo => 'nyo',
    AppLocale.ach => 'ach',
  };

  static Map<String, String> _sourceCatalog() {
    final source = <String, String>{
      for (final entry in _strings.entries)
        entry.key: entry.value[AppLocale.en] ?? entry.key,
      for (var index = 0; index < _uiLiterals.length; index++)
        '__literal_$index': _uiLiterals[index],
    };
    return source;
  }

  static Future<void> ensureBundle(AppLocale locale) async {
    if (locale == AppLocale.en || _downloaded.containsKey(locale)) return;
    final raw = await rootBundle.loadString(
      'assets/localization/${_apiCode(locale)}.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final bundle = decoded.map((key, value) => MapEntry(key, value.toString()));
    final expected = _sourceCatalog().keys.toSet();
    if (bundle.keys.toSet().difference(expected).isNotEmpty) {
      throw StateError('Bundled translation catalog has unrecognised keys');
    }
    // A bundle may legitimately lag behind `_uiLiterals`/`_strings` while a
    // language's translation work is still in progress — `tr()`/`literal()`
    // fall back to English per-key, so a partial bundle must not block
    // startup (`loadBundledTranslations()` awaits every locale) or block
    // switching to that language.
    _downloaded[locale] = bundle;
  }

  static Future<void> loadBundledTranslations() async {
    await Future.wait(
      AppLocale.values
          .where((locale) => locale != AppLocale.en)
          .map(ensureBundle),
    );
  }

  /// Every key that can produce built-in, user-visible copy.
  static Set<String> get catalogKeys => _sourceCatalog().keys.toSet();

  static String tr(BuildContext context, WidgetRef ref, String key) {
    final serviceText = ref.watch(offlineLanguageServiceProvider).t(key);
    if (serviceText != key) return serviceText;

    final locale = ref.watch(localeProvider);
    _activeLocale = locale;
    final downloaded = _downloaded[locale]?[key];
    if (downloaded != null && downloaded.isNotEmpty) return downloaded;
    return _strings[key]?[locale] ?? _strings[key]?[AppLocale.en] ?? key;
  }

  static String trFromLocale(String key, AppLocale locale) {
    final downloaded = _downloaded[locale]?[key];
    if (downloaded != null && downloaded.isNotEmpty) return downloaded;
    return _strings[key]?[locale] ?? _strings[key]?[AppLocale.en] ?? key;
  }

  static String literal(String text) {
    for (final entry in _strings.entries) {
      if (entry.value[AppLocale.en] == text) {
        return _downloaded[_activeLocale]?[entry.key] ??
            entry.value[_activeLocale] ??
            text;
      }
    }
    final index = _uiLiterals.indexOf(text);
    if (index < 0) return text;
    return _downloaded[_activeLocale]?['__literal_$index'] ?? text;
  }

  static const _strings = <String, Map<AppLocale, String>>{
    // ── App-wide ──
    'app_name': {
      AppLocale.en: 'AI Connect Africa',
      AppLocale.lg: 'AI Connect Africa',
      AppLocale.sw: 'AI Connect Africa',
    },
    'app_powered_by': {
      AppLocale.en: 'Powered by AI Connect Africa',
      AppLocale.lg: 'Ekozesebwa AI Connect Africa',
      AppLocale.sw: 'Inaendeshwa na AI Connect Africa',
    },
    'app_tagline': {
      AppLocale.en: 'Connecting Women to Opportunity',
      AppLocale.lg: 'Okuyunga Abakyala ku Mikisa',
      AppLocale.sw: 'Kuwaunganisha Wanawake na Fursa',
    },
    'online': {
      AppLocale.en: 'Online',
      AppLocale.lg: 'Ku mutimbagano',
      AppLocale.sw: 'Mtandaoni',
    },
    'offline': {
      AppLocale.en: 'Offline',
      AppLocale.lg: 'Toli ku mutimbagano',
      AppLocale.sw: 'Nje ya mtandao',
    },

    // ── Greeting ──
    'good_morning': {
      AppLocale.en: 'Good morning',
      AppLocale.lg: 'Wasuze otya',
      AppLocale.sw: 'Habari za asubuhi',
    },
    'good_afternoon': {
      AppLocale.en: 'Good afternoon',
      AppLocale.lg: 'Osiibye otya',
      AppLocale.sw: 'Habari za mchana',
    },
    'good_evening': {
      AppLocale.en: 'Good evening',
      AppLocale.lg: 'Oweddeko otya',
      AppLocale.sw: 'Habari za jioni',
    },

    // ── Home screen ──
    'hero_title': {
      AppLocale.en: 'Your journey. Your future.',
      AppLocale.lg: 'Olugendo lwo. Obudde bwo.',
      AppLocale.sw: 'Safari yako. Mustakabali wako.',
    },
    'hero_subtitle': {
      AppLocale.en:
          'Learn, Earn, Grow & Thrive — your path to opportunity starts here.',
      AppLocale.lg:
          'Soma, Funa, Kukula & Terera — ekkubo lyo ery\'emikisa litandikira wano.',
      AppLocale.sw:
          'Jifunze, Pata, Kua & Stawi — njia yako ya fursa inaanzia hapa.',
    },
    'continue_learning': {
      AppLocale.en: 'Continue Learning',
      AppLocale.lg: 'Weyongere Okusoma',
      AppLocale.sw: 'Endelea Kujifunza',
    },
    'day_streak': {
      AppLocale.en: 'day streak',
      AppLocale.lg: 'ennaku empita',
      AppLocale.sw: 'siku mfululizo',
    },
    'your_progress': {
      AppLocale.en: 'YOUR PROGRESS',
      AppLocale.lg: 'ENTAMBULA YO',
      AppLocale.sw: 'MAENDELEO YAKO',
    },
    'quick_actions': {
      AppLocale.en: 'QUICK ACTIONS',
      AppLocale.lg: 'BIKOLWA EBYANGUWA',
      AppLocale.sw: 'VITENDO VYA HARAKA',
    },
    'explore_pillars': {
      AppLocale.en: 'EXPLORE PILLARS',
      AppLocale.lg: 'NOONYEREZA EMPAGI',
      AppLocale.sw: 'GUNDUA NGUZO',
    },
    'all_services': {
      AppLocale.en: 'ALL SERVICES',
      AppLocale.lg: 'EMPEEREZA ZONNA',
      AppLocale.sw: 'HUDUMA ZOTE',
    },
    'courses': {
      AppLocale.en: 'Courses',
      AppLocale.lg: 'Amasomo',
      AppLocale.sw: 'Kozi',
    },
    'points': {
      AppLocale.en: 'Points',
      AppLocale.lg: 'Obubonero',
      AppLocale.sw: 'Pointi',
    },
    'streak': {
      AppLocale.en: 'Streak',
      AppLocale.lg: 'Empita',
      AppLocale.sw: 'Mfululizo',
    },

    // ── Pillars ──
    'learn': {
      AppLocale.en: 'Learn',
      AppLocale.lg: 'Yiga',
      AppLocale.sw: 'Jifunze',
    },
    'earn': {AppLocale.en: 'Earn', AppLocale.lg: 'Funa', AppLocale.sw: 'Pata'},
    'grow': {AppLocale.en: 'Grow', AppLocale.lg: 'Kukula', AppLocale.sw: 'Kua'},
    'thrive': {
      AppLocale.en: 'Thrive',
      AppLocale.lg: 'Terera',
      AppLocale.sw: 'Stawi',
    },
    'learn_desc': {
      AppLocale.en: 'Courses & digital skills',
      AppLocale.lg: 'Amasomo n\'obukugu bw\'ekikompyuta',
      AppLocale.sw: 'Kozi na ujuzi wa kidijitali',
    },
    'earn_desc': {
      AppLocale.en: 'Marketplace & finance',
      AppLocale.lg: 'Akatale n\'ensimbi',
      AppLocale.sw: 'Soko na fedha',
    },
    'grow_desc': {
      AppLocale.en: 'Mentorship & careers',
      AppLocale.lg: 'Obuyambi n\'emirimu',
      AppLocale.sw: 'Ushauri na kazi',
    },
    'thrive_desc': {
      AppLocale.en: 'Health & community',
      AppLocale.lg: 'Obulamu n\'ekibiina',
      AppLocale.sw: 'Afya na jamii',
    },

    // ── Quick actions ──
    'ask_ai': {
      AppLocale.en: 'Ask AI',
      AppLocale.lg: 'Buuza AI',
      AppLocale.sw: 'Uliza AI',
    },
    'find_jobs': {
      AppLocale.en: 'Find Jobs',
      AppLocale.lg: 'Noonya Emirimu',
      AppLocale.sw: 'Tafuta Kazi',
    },
    'marketplace': {
      AppLocale.en: 'Marketplace',
      AppLocale.lg: 'Akatale',
      AppLocale.sw: 'Soko',
    },

    // ── Services ──
    'finance': {
      AppLocale.en: 'Finance',
      AppLocale.lg: 'Ensimbi',
      AppLocale.sw: 'Fedha',
    },
    'mentors': {
      AppLocale.en: 'Mentors',
      AppLocale.lg: 'Abayambi',
      AppLocale.sw: 'Washauri',
    },
    'jobs': {
      AppLocale.en: 'Jobs',
      AppLocale.lg: 'Emirimu',
      AppLocale.sw: 'Kazi',
    },
    'skills': {
      AppLocale.en: 'Skills',
      AppLocale.lg: 'Obukugu',
      AppLocale.sw: 'Ujuzi',
    },
    'health': {
      AppLocale.en: 'Health',
      AppLocale.lg: 'Obulamu',
      AppLocale.sw: 'Afya',
    },
    'community': {
      AppLocale.en: 'Community',
      AppLocale.lg: 'Abantu',
      AppLocale.sw: 'Jamii',
    },
    'wellbeing': {
      AppLocale.en: 'Wellbeing',
      AppLocale.lg: 'Embeera ennungi',
      AppLocale.sw: 'Ustawi',
    },
    'settings': {
      AppLocale.en: 'Settings',
      AppLocale.lg: 'Entegeka',
      AppLocale.sw: 'Mipangilio',
    },
    'profile': {
      AppLocale.en: 'Profile',
      AppLocale.lg: 'Ebikukwatako',
      AppLocale.sw: 'Wasifu',
    },
    'ai_chat': {
      AppLocale.en: 'AI Chat',
      AppLocale.lg: 'Yogera ne AI',
      AppLocale.sw: 'Zungumza na AI',
    },
    'home': {
      AppLocale.en: 'Home',
      AppLocale.lg: 'Awaka',
      AppLocale.sw: 'Mwanzo',
    },
    'market': {
      AppLocale.en: 'Market',
      AppLocale.lg: 'Akatale',
      AppLocale.sw: 'Soko',
    },
    'chat': {
      AppLocale.en: 'Chat',
      AppLocale.lg: 'Emboozi',
      AppLocale.sw: 'Gumzo',
    },
    'nav_learn_earn': {
      AppLocale.en: 'Learn & Earn',
      AppLocale.lg: 'Yiga era Ofune',
      AppLocale.sw: 'Jifunze na Upate',
    },
    'nav_account': {
      AppLocale.en: 'Account',
      AppLocale.lg: 'Akawunti',
      AppLocale.sw: 'Akaunti',
    },

    // ── Daily tips ──
    'finance_tip': {
      AppLocale.en: 'Finance Tip',
      AppLocale.lg: 'Amagezi g\'Ensimbi',
      AppLocale.sw: 'Kidokezo cha Fedha',
    },
    'community_tip': {
      AppLocale.en: 'Community Tip',
      AppLocale.lg: 'Amagezi g\'Ekibiina',
      AppLocale.sw: 'Kidokezo cha Jamii',
    },
    'business_tip': {
      AppLocale.en: 'Business Tip',
      AppLocale.lg: 'Amagezi g\'Obusubuzi',
      AppLocale.sw: 'Kidokezo cha Biashara',
    },
    'health_tip': {
      AppLocale.en: 'Health Tip',
      AppLocale.lg: 'Amagezi g\'Obulamu',
      AppLocale.sw: 'Kidokezo cha Afya',
    },
    'skills_tip': {
      AppLocale.en: 'Skills Tip',
      AppLocale.lg: 'Amagezi g\'Obukugu',
      AppLocale.sw: 'Kidokezo cha Ujuzi',
    },
    'tip_save': {
      AppLocale.en:
          'Save at least 10% of your income each week — small amounts grow fast!',
      AppLocale.lg:
          'Tereka watoowozo 10% ey\'ensimbi zo buli wiiki — ebitono bikula mangu!',
      AppLocale.sw:
          'Weka akiba angalau 10% ya mapato yako kila wiki — kiasi kidogo hukua haraka!',
    },
    'tip_sacco': {
      AppLocale.en:
          'Join a local savings group (SACCO) to access loans and build credit.',
      AppLocale.lg:
          'Yingira mu kibiina ky\'okuterekawo (SACCO) ofune ebbanja era ozimbe okwesigwa.',
      AppLocale.sw:
          'Jiunge na kikundi cha akiba (SACCO) kupata mikopo na kujenga sifa ya mkopo.',
    },
    'tip_photos': {
      AppLocale.en:
          'Take photos of your products in natural light for better online sales.',
      AppLocale.lg:
          'Kuba ebifaananyi by\'ebyobusubuzi byo mu musana ogw\'obutonde ofune okutunda obulungi.',
      AppLocale.sw:
          'Piga picha za bidhaa zako kwenye mwanga wa asili kwa mauzo bora mtandaoni.',
    },
    'tip_water': {
      AppLocale.en:
          'Drink at least 8 glasses of water daily for better health and energy.',
      AppLocale.lg:
          'Okunywa watoowozo gilasi 8 ez\'amazzi buli lunaku olw\'obulamu obulungi n\'amaanyi.',
      AppLocale.sw:
          'Kunywa angalau glasi 8 za maji kila siku kwa afya na nishati bora.',
    },
    'tip_digital': {
      AppLocale.en:
          'Practice one new digital skill each week — consistency beats speed.',
      AppLocale.lg:
          'Gezaako obukugu bw\'ekikompyuta obuggya buli wiiki — okugoberera kusinga okwanguyiriza.',
      AppLocale.sw:
          'Fanya mazoezi ya ujuzi mpya wa kidijitali kila wiki — uthabiti unashinda kasi.',
    },

    // ── Onboarding ──
    'welcome_to': {
      AppLocale.en: 'Welcome to\nAI Connect Africa',
      AppLocale.lg: 'Tukusanyukira ku\nAI Connect Africa',
      AppLocale.sw: 'Karibu kwenye\nAI Connect Africa',
    },
    'welcome_desc': {
      AppLocale.en:
          'Your digital companion for learning, earning, growing, and thriving. Works online and offline — your progress is always safe.',
      AppLocale.lg:
          'Munno wo ow\'ekikompyuta okusoma, okufuna, okukula, n\'okuterera. Akola ku mutimbagano ne bw\'otaba — entambula yo etereka.',
      AppLocale.sw:
          'Mwenzako wa kidijitali wa kujifunza, kupata, kukua, na kustawi. Inafanya kazi mtandaoni na nje — maendeleo yako ni salama daima.',
    },
    'whats_your_name': {
      AppLocale.en: "What's your name?",
      AppLocale.lg: "Erinnya lyo ggwe ani?",
      AppLocale.sw: "Jina lako ni nani?",
    },
    'enter_your_name': {
      AppLocale.en: 'Enter your name',
      AppLocale.lg: 'Wandiika erinnya lyo',
      AppLocale.sw: 'Ingiza jina lako',
    },
    'continue_btn': {
      AppLocale.en: 'Continue',
      AppLocale.lg: 'Okwongera',
      AppLocale.sw: 'Endelea',
    },
    'back': {
      AppLocale.en: 'Back',
      AppLocale.lg: 'Nnyuma',
      AppLocale.sw: 'Rudi',
    },
    'start_journey': {
      AppLocale.en: 'Start your journey',
      AppLocale.lg: 'Sooka olugendo lwo',
      AppLocale.sw: 'Anza safari yako',
    },
    'about_you': {
      AppLocale.en: 'About you',
      AppLocale.lg: 'Ebikukwatako',
      AppLocale.sw: 'Kuhusu wewe',
    },
    'about_you_desc': {
      AppLocale.en:
          'This helps us personalise your experience with relevant opportunities and resources.',
      AppLocale.lg:
          'Kino kituyamba okukukolera ebikugyanira mu mbeera n\'ebyobulamu.',
      AppLocale.sw:
          'Hii inatusaidia kubinafsisha uzoefu wako na fursa na rasilimali zinazofaa.',
    },
    'what_describes_you': {
      AppLocale.en: 'What best describes you?',
      AppLocale.lg: 'Kiki ekikukubaganya?',
      AppLocale.sw: 'Ni nini kinachokuelezea vyema?',
    },
    'where_based': {
      AppLocale.en: 'Where are you based?',
      AppLocale.lg: 'Obeera wa?',
      AppLocale.sw: 'Uko wapi?',
    },
    'location_hint': {
      AppLocale.en: 'e.g. Kampala, Mukono, Mbale',
      AppLocale.lg: 'okugeza Kampala, Mukono, Mbale',
      AppLocale.sw: 'mf. Kampala, Mukono, Mbale',
    },
    'choose_language': {
      AppLocale.en: 'Choose your language',
      AppLocale.lg: 'Londa olulimi lwo',
      AppLocale.sw: 'Chagua lugha yako',
    },
    'language_selection_help': {
      AppLocale.en: 'Select the language you want to use in the app',
      AppLocale.lg: 'Londa olulimi lw’oyagala okukozesa mu app',
      AppLocale.sw: 'Chagua lugha unayotaka kutumia katika programu',
    },
    'please_enter_name': {
      AppLocale.en: 'Please enter your name',
      AppLocale.lg: 'Nsaba wandiike erinnya lyo',
      AppLocale.sw: 'Tafadhali ingiza jina lako',
    },

    // ── Auth (phone / OTP) ──
    'enter_phone_number': {
      AppLocale.en: 'Enter your phone number',
      AppLocale.lg: 'Wandiika ennamba yo eya essimu',
      AppLocale.sw: 'Ingiza nambari yako ya simu',
    },
    'phone_number_hint': {
      AppLocale.en: 'e.g. 700 000 000',
      AppLocale.lg: 'okugeza 700 000 000',
      AppLocale.sw: 'mf. 700 000 000',
    },
    'send_code': {
      AppLocale.en: 'Send code',
      AppLocale.lg: 'Sindika koodi',
      AppLocale.sw: 'Tuma msimbo',
    },
    'enter_otp_code': {
      AppLocale.en: 'Enter the code we sent you',
      AppLocale.lg: 'Wandiika koodi gye tukusindikidde',
      AppLocale.sw: 'Ingiza msimbo tuliokutumia',
    },
    'otp_code_hint': {
      AppLocale.en: '6-digit code',
      AppLocale.lg: 'Koodi ey\'ennamba 6',
      AppLocale.sw: 'Msimbo wa tarakimu 6',
    },
    'verify_code': {
      AppLocale.en: 'Verify code',
      AppLocale.lg: 'Kakasa koodi',
      AppLocale.sw: 'Thibitisha msimbo',
    },
    'resend_code': {
      AppLocale.en: 'Resend code',
      AppLocale.lg: 'Ddamu osindike koodi',
      AppLocale.sw: 'Tuma tena msimbo',
    },
    'invalid_phone_number': {
      AppLocale.en: 'Please enter a valid phone number',
      AppLocale.lg: 'Nsaba wandiike ennamba entuufu eya essimu',
      AppLocale.sw: 'Tafadhali ingiza nambari sahihi ya simu',
    },
    'invalid_otp_code': {
      AppLocale.en: 'Please enter the code we sent you',
      AppLocale.lg: 'Nsaba wandiike koodi gye tukusindikidde',
      AppLocale.sw: 'Tafadhali ingiza msimbo tuliokutumia',
    },
    'otp_send_failed': {
      AppLocale.en: 'Could not send code. Please try again.',
      AppLocale.lg: 'Tetusobodde kusindika koodi. Ddamu ogezeeko.',
      AppLocale.sw: 'Imeshindwa kutuma msimbo. Tafadhali jaribu tena.',
    },
    'otp_verify_failed': {
      AppLocale.en: 'That code didn\'t work. Please try again.',
      AppLocale.lg: 'Koodi eyo teyakoze. Ddamu ogezeeko.',
      AppLocale.sw: 'Msimbo huo haukufanya kazi. Tafadhali jaribu tena.',
    },
    'windows_recaptcha_note': {
      AppLocale.en:
          'On Windows, you may briefly see a verification step before your code is sent.',
      AppLocale.lg:
          'Ku Windows, oyinza okulaba akadde ak\'okukakasa nga koodi tennasindikwa.',
      AppLocale.sw:
          'Kwenye Windows, huenda ukaona hatua fupi ya uthibitisho kabla msimbo haujatumwa.',
    },

    // ── Roles ──
    'role_entrepreneur': {
      AppLocale.en: 'Entrepreneur',
      AppLocale.lg: 'Omusubuzi',
      AppLocale.sw: 'Mjasiriamali',
    },
    'role_entrepreneur_desc': {
      AppLocale.en: 'I run or want to start a business',
      AppLocale.lg: 'Nkola obusubuzi oba njagala okutandika',
      AppLocale.sw: 'Ninaendesha au nataka kuanzisha biashara',
    },
    'role_farmer': {
      AppLocale.en: 'Farmer',
      AppLocale.lg: 'Omulimi',
      AppLocale.sw: 'Mkulima',
    },
    'role_farmer_desc': {
      AppLocale.en: 'I work in agriculture or agribusiness',
      AppLocale.lg: 'Nkola mu bulimi',
      AppLocale.sw: 'Ninafanya kazi katika kilimo',
    },
    'role_student': {
      AppLocale.en: 'Student',
      AppLocale.lg: 'Omuyizi',
      AppLocale.sw: 'Mwanafunzi',
    },
    'role_student_desc': {
      AppLocale.en: 'I am currently studying or in training',
      AppLocale.lg: 'Ndi mu kusoma oba okutendekebwa',
      AppLocale.sw: 'Ninasoma au ninafunzwa sasa',
    },
    'role_job_seeker': {
      AppLocale.en: 'Job Seeker',
      AppLocale.lg: 'Anoonya omulimu',
      AppLocale.sw: 'Mtafuta kazi',
    },
    'role_job_seeker_desc': {
      AppLocale.en: 'I am looking for employment',
      AppLocale.lg: 'Nnoonya omulimu',
      AppLocale.sw: 'Ninatafuta ajira',
    },
    'role_leader': {
      AppLocale.en: 'Community Leader',
      AppLocale.lg: 'Omukulembeze w\'ekibiina',
      AppLocale.sw: 'Kiongozi wa jamii',
    },
    'role_leader_desc': {
      AppLocale.en: 'I lead or organize in my community',
      AppLocale.lg: 'Nkulembera oba ntegeka mu kibiina kyange',
      AppLocale.sw: 'Ninaongoza au ninapanga katika jamii yangu',
    },
    'role_artisan': {
      AppLocale.en: 'Artisan / Creator',
      AppLocale.lg: 'Omukozi w\'emikono',
      AppLocale.sw: 'Fundi / Muundaji',
    },
    'role_artisan_desc': {
      AppLocale.en: 'I create handmade goods or crafts',
      AppLocale.lg: 'Nkola ebintu n\'emikono gyange',
      AppLocale.sw: 'Ninaunda bidhaa za mikono au sanaa',
    },

    // ── Settings ──
    'appearance': {
      AppLocale.en: 'Appearance',
      AppLocale.lg: 'Endabika',
      AppLocale.sw: 'Muonekano',
    },
    'language': {
      AppLocale.en: 'Language',
      AppLocale.lg: 'Olulimi',
      AppLocale.sw: 'Lugha',
    },
    'app_language': {
      AppLocale.en: 'App Language',
      AppLocale.lg: 'Olulimi lw\'App',
      AppLocale.sw: 'Lugha ya App',
    },
    'data_sync': {
      AppLocale.en: 'Data & Sync',
      AppLocale.lg: 'Ebikukwatako n\'Okukolagana',
      AppLocale.sw: 'Data na Usawazishaji',
    },
    'notifications': {
      AppLocale.en: 'Notifications',
      AppLocale.lg: 'Amawulire',
      AppLocale.sw: 'Arifa',
    },
    'about': {
      AppLocale.en: 'About',
      AppLocale.lg: 'Ebikwata ku',
      AppLocale.sw: 'Kuhusu',
    },

    // ── Nav ──
    'new_chat': {
      AppLocale.en: 'New chat',
      AppLocale.lg: 'Emboozi empya',
      AppLocale.sw: 'Mazungumzo mapya',
    },
    'ask_anything': {
      AppLocale.en: 'Ask anything...',
      AppLocale.lg: 'Buuza ekintu kyonna...',
      AppLocale.sw: 'Uliza chochote...',
    },
    'thinking': {
      AppLocale.en: 'Thinking...',
      AppLocale.lg: 'Nlowooza...',
      AppLocale.sw: 'Nafikiri...',
    },

    // ── Learn screen ──
    'knowledge_is_power': {
      AppLocale.en: 'Knowledge is power',
      AppLocale.lg: 'Amagezi ge Amaanyi',
      AppLocale.sw: 'Maarifa ni nguvu',
    },
    'knowledge_is_power_desc': {
      AppLocale.en:
          'Practical courses designed for women — from digital skills to business management, all in your language.',
      AppLocale.lg:
          'Amasomo ag\'obukwatirivu ga bakazi — okuva mu bukugu bw\'ekikompyuta okutuuka mu kulabirira obusubuzi, byonna mu lulimi lwo.',
      AppLocale.sw:
          'Kozi za vitendo zilizoundwa kwa wanawake — kutoka ujuzi wa kidijitali hadi usimamizi wa biashara, zote kwa lugha yako.',
    },
    'next_milestone': {
      AppLocale.en: 'Next milestone',
      AppLocale.lg: 'Ekigendererwa Ekiddako',
      AppLocale.sw: 'Lengo linalofuata',
    },
    'featured_courses': {
      AppLocale.en: 'Featured Courses',
      AppLocale.lg: 'Amasomo Agasingayo',
      AppLocale.sw: 'Kozi Maalum',
    },
    'browse_topics': {
      AppLocale.en: 'Browse Topics',
      AppLocale.lg: 'Noonyereza Ebyagenda',
      AppLocale.sw: 'Vinjari Mada',
    },
    'practical_skills_sub': {
      AppLocale.en: 'Practical skills for everyday life',
      AppLocale.lg: 'Obukugu obw\'okukozesa buli lunaku',
      AppLocale.sw: 'Ujuzi wa vitendo kwa maisha ya kila siku',
    },
    'ai_learning_assistant': {
      AppLocale.en: 'AI Learning Assistant',
      AppLocale.lg: 'Omuyambi w\'Okusoma wa AI',
      AppLocale.sw: 'Msaidizi wa AI wa Kujifunza',
    },
    'ai_learning_desc': {
      AppLocale.en: 'Ask any question and get instant help',
      AppLocale.lg: 'Buuza ekibuuzo kyonna ofune obuyambi mangu',
      AppLocale.sw: 'Uliza swali lolote na upate msaada wa haraka',
    },
    'ask_ai_assistant': {
      AppLocale.en: 'Ask AI Assistant',
      AppLocale.lg: 'Buuza Omuyambi wa AI',
      AppLocale.sw: 'Uliza Msaidizi wa AI',
    },
    'ask_ai_assistant_desc': {
      AppLocale.en:
          'Get personalised answers on business, farming, health, and more',
      AppLocale.lg:
          'Funa ennyini z\'obukwatirivu ku busubuzi, bulimi, obulamu, n\'ebirala',
      AppLocale.sw:
          'Pata majibu ya kibinafsi kuhusu biashara, kilimo, afya, na zaidi',
    },
    'lessons': {
      AppLocale.en: 'lessons',
      AppLocale.lg: 'amasomo',
      AppLocale.sw: 'masomo',
    },
    'in_progress': {
      AppLocale.en: 'In Progress',
      AppLocale.lg: 'Mu Entambula',
      AppLocale.sw: 'Inaendelea',
    },
    'cat_digital': {
      AppLocale.en: 'Digital Skills',
      AppLocale.lg: 'Obukugu bw\'Ekikompyuta',
      AppLocale.sw: 'Ujuzi wa Kidijitali',
    },
    'cat_digital_desc': {
      AppLocale.en: 'Computers, internet, and mobile basics',
      AppLocale.lg: 'Ebyekikompyuta, mutimbagano, n\'omukono gw\'ettelefooni',
      AppLocale.sw: 'Kompyuta, intaneti, na misingi ya simu',
    },
    'cat_finance_lit': {
      AppLocale.en: 'Financial Literacy',
      AppLocale.lg: 'Okumanya Ensimbi',
      AppLocale.sw: 'Elimu ya Fedha',
    },
    'cat_finance_lit_desc': {
      AppLocale.en: 'Budgeting, savings, and money management',
      AppLocale.lg: 'Okubala ensimbi, okuterekawo, n\'okulabirira ensimbi',
      AppLocale.sw: 'Bajeti, akiba, na usimamizi wa pesa',
    },
    'cat_entrepreneur': {
      AppLocale.en: 'Entrepreneurship',
      AppLocale.lg: 'Obusubuzi',
      AppLocale.sw: 'Ujasiriamali',
    },
    'cat_entrepreneur_desc': {
      AppLocale.en: 'Start and grow your business',
      AppLocale.lg: 'Tandika era okule obusubuzi bwo',
      AppLocale.sw: 'Anza na kukua biashara yako',
    },
    'cat_agri': {
      AppLocale.en: 'Agriculture',
      AppLocale.lg: 'Obulimi',
      AppLocale.sw: 'Kilimo',
    },
    'cat_agri_desc': {
      AppLocale.en: 'Modern farming techniques and agribusiness',
      AppLocale.lg: 'Enkolagana ez\'obulimi obupya n\'obusubuzi bw\'ebyobulimi',
      AppLocale.sw: 'Mbinu za kisasa za kilimo na biashara ya kilimo',
    },
    'cat_health_nut': {
      AppLocale.en: 'Health & Nutrition',
      AppLocale.lg: 'Obulamu n\'Ebyokulya',
      AppLocale.sw: 'Afya na Lishe',
    },
    'cat_health_nut_desc': {
      AppLocale.en: 'Family health, nutrition, and wellness',
      AppLocale.lg: 'Obulamu bw\'oluganda, ebyokulya, n\'emirembe',
      AppLocale.sw: 'Afya ya familia, lishe, na ustawi',
    },
    'cat_leadership': {
      AppLocale.en: 'Leadership',
      AppLocale.lg: 'Obukulu',
      AppLocale.sw: 'Uongozi',
    },
    'cat_leadership_desc': {
      AppLocale.en: 'Community leadership and advocacy skills',
      AppLocale.lg: 'Obukulu bw\'ekibiina n\'obukugu bw\'okwogera',
      AppLocale.sw: 'Uongozi wa jamii na ujuzi wa utetezi',
    },

    // ── Marketplace screen ──
    'sell_products': {
      AppLocale.en: 'Sell your products & services',
      AppLocale.lg: 'Tunda ebintu byo n\'empeereza zo',
      AppLocale.sw: 'Uza bidhaa na huduma zako',
    },
    'sell_products_desc': {
      AppLocale.en:
          'Connect with buyers in your community and beyond. List your products, set prices, and grow your business.',
      AppLocale.lg:
          'Kolagana n\'abaagula mu kibiina kyo n\'ebirala. Wandiika ebintu byo, teekawo emiwendo, era okule obusubuzi bwo.',
      AppLocale.sw:
          'Unganika na wanunuzi katika jamii yako na zaidi. Orodhesha bidhaa zako, weka bei, na kukua biashara yako.',
    },
    'list_product_btn': {
      AppLocale.en: 'List a Product',
      AppLocale.lg: 'Wandiika Ekintu',
      AppLocale.sw: 'Orodhesha Bidhaa',
    },
    'categories': {
      AppLocale.en: 'Categories',
      AppLocale.lg: 'Emitono',
      AppLocale.sw: 'Makundi',
    },
    'browse_products': {
      AppLocale.en: 'Browse products and services',
      AppLocale.lg: 'Noonyereza ebintu n\'empeereza',
      AppLocale.sw: 'Vinjari bidhaa na huduma',
    },
    'featured_listings': {
      AppLocale.en: 'Featured Listings',
      AppLocale.lg: 'Ebintu Ebyasinguliriziddwa',
      AppLocale.sw: 'Orodha Zilizoangaziwa',
    },
    'popular_products_desc': {
      AppLocale.en: 'Popular products from women in your area',
      AppLocale.lg: 'Ebintu ebisinganyiziddwa okuva ku bakazi mu kifo kyo',
      AppLocale.sw: 'Bidhaa maarufu kutoka kwa wanawake eneo lako',
    },
    'see_all': {
      AppLocale.en: 'See all',
      AppLocale.lg: 'Laba byonna',
      AppLocale.sw: 'Ona yote',
    },
    'listing_title_hint': {
      AppLocale.en: 'e.g. Fresh Organic Vegetables',
      AppLocale.lg: 'okugeza Enva endiirwa ez\'obutonde',
      AppLocale.sw: 'mf. Mboga za asili',
    },
    'listing_price_hint': {
      AppLocale.en: 'Price (UGX)',
      AppLocale.lg: 'Omuwendo (UGX)',
      AppLocale.sw: 'Bei (UGX)',
    },
    'select_category_label': {
      AppLocale.en: 'Category',
      AppLocale.lg: 'Ekika',
      AppLocale.sw: 'Aina',
    },
    'select_category_error': {
      AppLocale.en: 'Please select a category',
      AppLocale.lg: 'Nsaba olondewo ekika',
      AppLocale.sw: 'Tafadhali chagua aina',
    },
    'listings_load_error': {
      AppLocale.en: 'Could not load listings',
      AppLocale.lg: 'Tekisobose kutikka lukalala lw’ebitundibwa',
      AppLocale.sw: 'Imeshindikana kupakia orodha',
    },
    'listing_title_error': {
      AppLocale.en: 'Please enter a product title',
      AppLocale.lg: 'Nsaba wandiike erinnya ly\'ekintu',
      AppLocale.sw: 'Tafadhali ingiza jina la bidhaa',
    },
    'listing_price_error': {
      AppLocale.en: 'Please enter a valid price',
      AppLocale.lg: 'Nsaba wandiike omuwendo omutuufu',
      AppLocale.sw: 'Tafadhali ingiza bei sahihi',
    },
    'no_listings_yet': {
      AppLocale.en: 'No listings yet — be the first to list a product!',
      AppLocale.lg:
          'Tewali kintu kyawandiikibwa — beera owasooka okuwandiika ekintu!',
      AppLocale.sw: 'Hakuna bidhaa bado — kuwa wa kwanza kuorodhesha bidhaa!',
    },
    'no_listings_in_category': {
      AppLocale.en: 'No listings in this category yet',
      AppLocale.lg: 'Tewali kintu mu kika kino',
      AppLocale.sw: 'Hakuna bidhaa katika aina hii bado',
    },
    'listing_as': {
      AppLocale.en: 'Listing as',
      AppLocale.lg: 'Owandiika nga',
      AppLocale.sw: 'Unaorodhesha kama',
    },
    'clear_filter': {
      AppLocale.en: 'Clear filter',
      AppLocale.lg: 'Ggyawo okulonda',
      AppLocale.sw: 'Futa kichujio',
    },
    'cat_crafts': {
      AppLocale.en: 'Crafts',
      AppLocale.lg: 'Ebikozesebwa emikono',
      AppLocale.sw: 'Ufundi',
    },
    'cat_food_drink': {
      AppLocale.en: 'Food & Drink',
      AppLocale.lg: 'Ebyokulya n\'Okunywa',
      AppLocale.sw: 'Chakula na Vinywaji',
    },
    'cat_fashion': {
      AppLocale.en: 'Fashion',
      AppLocale.lg: 'Engoye',
      AppLocale.sw: 'Mitindo',
    },
    'cat_beauty': {
      AppLocale.en: 'Beauty',
      AppLocale.lg: 'Obuwanguzi',
      AppLocale.sw: 'Urembo',
    },
    'cat_services': {
      AppLocale.en: 'Services',
      AppLocale.lg: 'Empeereza',
      AppLocale.sw: 'Huduma',
    },

    // ── Mentorship screen ──
    'grow_with_guidance': {
      AppLocale.en: 'Grow with guidance',
      AppLocale.lg: 'Kula n\'Amagezi',
      AppLocale.sw: 'Kua kwa mwongozo',
    },
    'grow_with_guidance_desc': {
      AppLocale.en:
          'Every successful woman had someone who believed in her. Find your mentor or become one.',
      AppLocale.lg:
          'Omukazi buli omu eyakuwerera yaali n\'omuntu eyamwesiga. Noonyereza omuyambi wo oba gwa obenga.',
      AppLocale.sw:
          'Kila mwanamke aliyefanikiwa alikuwa na mtu aliyemwamini. Tafuta mshauri wako au uwe mmoja.',
    },
    'find_mentor_title': {
      AppLocale.en: 'Find a Mentor',
      AppLocale.lg: 'Noonyereza Omuyambi',
      AppLocale.sw: 'Tafuta Mshauri',
    },
    'find_mentor_desc': {
      AppLocale.en: 'Connect with experienced women who can guide you',
      AppLocale.lg:
          'Kolagana n\'abakazi ab\'obutegefu abasobola okukuyongereza',
      AppLocale.sw: 'Unganika na wanawake wenye uzoefu wanaoweza kukuongoza',
    },
    'become_mentor_title': {
      AppLocale.en: 'Become a Mentor',
      AppLocale.lg: 'Gwa Omuyambi',
      AppLocale.sw: 'Kuwa Mshauri',
    },
    'become_mentor_desc': {
      AppLocale.en: 'Share your experience and uplift others',
      AppLocale.lg: 'Gabana obutegefu bwo era oyinze abalala',
      AppLocale.sw: 'Shiriki uzoefu wako na inua wengine',
    },
    'connect_btn': {
      AppLocale.en: 'Connect',
      AppLocale.lg: 'Kolagana',
      AppLocale.sw: 'Unganika',
    },
    'apply_to_mentor': {
      AppLocale.en: 'Apply to Mentor',
      AppLocale.lg: 'Saba Okuba Omuyambi',
      AppLocale.sw: 'Omba Kuwa Mshauri',
    },
    'share_knowledge': {
      AppLocale.en: 'Share your knowledge',
      AppLocale.lg: 'Gabana Amagezi go',
      AppLocale.sw: 'Shiriki maarifa yako',
    },
    'share_knowledge_desc': {
      AppLocale.en:
          'Help other women grow by sharing your skills and experience. Being a mentor is one of the most impactful things you can do.',
      AppLocale.lg:
          'Yamba abakazi abalala okukula nga ogabana obukugu bwo n\'obutegefu bwo. Okuba omuyambi kye kimu mu bintu ebimu ebyongeza ennyo.',
      AppLocale.sw:
          'Saidia wanawake wengine kukua kwa kushiriki ujuzi na uzoefu wako. Kuwa mshauri ni moja ya mambo yenye athari zaidi unayoweza kufanya.',
    },
    'yrs_experience': {
      AppLocale.en: 'yrs experience',
      AppLocale.lg: 'emyaka gy\'obutegefu',
      AppLocale.sw: 'miaka ya uzoefu',
    },

    // ── Health screen ──
    'your_health_matters': {
      AppLocale.en: 'Your health matters',
      AppLocale.lg: 'Obulamu bwo bwa muvubuka',
      AppLocale.sw: 'Afya yako ni muhimu',
    },
    'your_health_matters_desc': {
      AppLocale.en:
          'Access trusted health information and connect with services in your community.',
      AppLocale.lg:
          'Funa amakwate g\'obulamu ag\'okwesiga era okolagane n\'empeereza mu kibiina kyo.',
      AppLocale.sw:
          'Pata habari za afya za kuaminika na unganike na huduma katika jamii yako.',
    },
    'health_resources': {
      AppLocale.en: 'Health Resources',
      AppLocale.lg: 'Ebikwatira ku Obulamu',
      AppLocale.sw: 'Rasilimali za Afya',
    },
    'trusted_health_desc': {
      AppLocale.en: 'Trusted information for you and your family',
      AppLocale.lg: 'Amakwate ag\'okwesiga ku lwenyo n\'oluganda lwo',
      AppLocale.sw: 'Habari za kuaminika kwako na familia yako',
    },
    'maternal_health': {
      AppLocale.en: 'Maternal Health',
      AppLocale.lg: 'Obulamu bw\'Omuzadde',
      AppLocale.sw: 'Afya ya Uzazi',
    },
    'maternal_health_desc': {
      AppLocale.en: 'Pregnancy, postnatal care, and family planning',
      AppLocale.lg: 'Okubeerawo, okukuuma omuzadde, n\'okutegekereza oluganda',
      AppLocale.sw: 'Ujauzito, huduma baada ya kuzaa, na upangaji uzazi',
    },
    'nutrition_guide': {
      AppLocale.en: 'Nutrition Guide',
      AppLocale.lg: 'Ebiragiro by\'Ebyokulya',
      AppLocale.sw: 'Mwongozo wa Lishe',
    },
    'nutrition_guide_desc': {
      AppLocale.en: 'Healthy eating for you and your children',
      AppLocale.lg: 'Okulya obulungi ku lwenyo n\'abaana bo',
      AppLocale.sw: 'Ulaji bora kwako na watoto wako',
    },
    'child_health': {
      AppLocale.en: 'Child Health',
      AppLocale.lg: 'Obulamu bw\'Omwana',
      AppLocale.sw: 'Afya ya Mtoto',
    },
    'child_health_desc': {
      AppLocale.en: 'Immunisation, common illnesses, and child care',
      AppLocale.lg: 'Enkangavvulo, emikungulu egy\'omukutu, n\'okukuuma abaana',
      AppLocale.sw: 'Chanjo, magonjwa ya kawaida, na utunzaji wa mtoto',
    },
    'mental_wellness': {
      AppLocale.en: 'Mental Wellness',
      AppLocale.lg: 'Emirembe gw\'Omutima',
      AppLocale.sw: 'Afya ya Akili',
    },
    'mental_wellness_desc': {
      AppLocale.en: 'Stress management, self-care, and emotional support',
      AppLocale.lg: 'Okukuuma ettima, okwekuuma, n\'obuyambi bw\'emirembe',
      AppLocale.sw: 'Usimamizi wa msongo, kujitunza, na msaada wa kihisia',
    },
    'nearby_services_title': {
      AppLocale.en: 'Nearby Services',
      AppLocale.lg: 'Empeereza Eziri Kumpi',
      AppLocale.sw: 'Huduma Zilizo Karibu',
    },
    'nearby_services_sub': {
      AppLocale.en: 'Health facilities and services in your area',
      AppLocale.lg: 'Ebitalo n\'empeereza z\'obulamu mu kifo kyo',
      AppLocale.sw: 'Vituo vya afya na huduma eneo lako',
    },
    'get_directions': {
      AppLocale.en: 'Directions',
      AppLocale.lg: 'Ekkubo',
      AppLocale.sw: 'Elekeo',
    },
    'km_away': {
      AppLocale.en: 'km away',
      AppLocale.lg: 'km ewala',
      AppLocale.sw: 'km mbali',
    },

    // ── AI Chat screen ──
    // Financial hub
    'financial_hub': {
      AppLocale.en: 'Financial Hub',
      AppLocale.lg: 'Ekifo ky\'Ensimbi',
      AppLocale.sw: 'Kituo cha Fedha',
    },
    'financial_tools': {
      AppLocale.en: 'Financial Tools',
      AppLocale.lg: 'Ebikozesebwa mu nsimbi',
      AppLocale.sw: 'Zana za Fedha',
    },
    'manage_money_wisely': {
      AppLocale.en: 'Manage your money wisely',
      AppLocale.lg: 'Labirira ensimbi zo n\'amagezi',
      AppLocale.sw: 'Simamia pesa zako kwa busara',
    },
    'savings_tracker': {
      AppLocale.en: 'Savings Tracker',
      AppLocale.lg: 'Okulondoola okweterekera',
      AppLocale.sw: 'Kifuatilia Akiba',
    },
    'savings_tracker_desc': {
      AppLocale.en: 'Set goals and track your savings progress',
      AppLocale.lg: 'Teekawo ebiruubirirwa era olondoolere okutereka kwo',
      AppLocale.sw: 'Weka malengo na fuatilia maendeleo ya akiba',
    },
    'budget_planner': {
      AppLocale.en: 'Budget Planner',
      AppLocale.lg: 'Enteekateeka y\'embalirira',
      AppLocale.sw: 'Mpanga Bajeti',
    },
    'budget_planner_desc': {
      AppLocale.en: 'Plan your income and expenses',
      AppLocale.lg: 'Teekateeka ennyingiza n\'ensaasaanya yo',
      AppLocale.sw: 'Panga mapato na matumizi yako',
    },
    'sacco_directory': {
      AppLocale.en: 'SACCO Directory',
      AppLocale.lg: 'Olukalala lwa SACCO',
      AppLocale.sw: 'Orodha ya SACCO',
    },
    'sacco_directory_desc': {
      AppLocale.en: 'Find savings groups and cooperatives near you',
      AppLocale.lg: 'Noonya ebibiina by\'okutereka ebiri kumpi naawe',
      AppLocale.sw: 'Tafuta vikundi vya akiba na vyama karibu nawe',
    },
    'mobile_money_guide': {
      AppLocale.en: 'Mobile Money Guide',
      AppLocale.lg: 'Ekitabo kya mobile money',
      AppLocale.sw: 'Mwongozo wa Mobile Money',
    },
    'mobile_money_guide_desc': {
      AppLocale.en: 'Learn to send, receive, and save with mobile money',
      AppLocale.lg: 'Yiga okusindika, okufuna, n\'okutereka ne mobile money',
      AppLocale.sw: 'Jifunze kutuma, kupokea, na kuweka akiba kwa mobile money',
    },
    'financial_literacy': {
      AppLocale.en: 'Financial Literacy',
      AppLocale.lg: 'Okumanya ensimbi',
      AppLocale.sw: 'Elimu ya Fedha',
    },
    'build_money_knowledge': {
      AppLocale.en: 'Build your money knowledge',
      AppLocale.lg: 'Yongera okumanya kwo ku nsimbi',
      AppLocale.sw: 'Jenga maarifa yako ya pesa',
    },
    'finance_hero_title': {
      AppLocale.en: 'Take control of your finances',
      AppLocale.lg: 'Fuga ensimbi zo',
      AppLocale.sw: 'Dhibiti fedha zako',
    },
    'finance_hero_desc': {
      AppLocale.en:
          'Tools and resources to help you save, budget, and grow your money.',
      AppLocale.lg:
          'Ebikozesebwa okukuyamba okutereka, okubala, n\'okukuza ensimbi zo.',
      AppLocale.sw:
          'Zana na rasilimali za kukusaidia kuweka akiba, kupanga bajeti, na kukuza pesa.',
    },
    'tip_start_small_title': {
      AppLocale.en: 'Start Small',
      AppLocale.lg: 'Tandikira ku kitono',
      AppLocale.sw: 'Anza Kidogo',
    },
    'tip_start_small_desc': {
      AppLocale.en: 'Even saving 500 UGX a day adds up over time',
      AppLocale.lg: 'N\'okutereka UGX 500 buli lunaku kuyinza okukula',
      AppLocale.sw: 'Hata kuweka 500 UGX kwa siku hukua baada ya muda',
    },
    'tip_track_expenses_title': {
      AppLocale.en: 'Track Expenses',
      AppLocale.lg: 'Londoola ensaasaanya',
      AppLocale.sw: 'Fuatilia Matumizi',
    },
    'tip_track_expenses_desc': {
      AppLocale.en: 'Know where your money goes each week',
      AppLocale.lg: 'Manya ensimbi zo gye zigenda buli wiiki',
      AppLocale.sw: 'Jua pesa zako zinaenda wapi kila wiki',
    },
    'tip_join_sacco_title': {
      AppLocale.en: 'Join a SACCO',
      AppLocale.lg: 'Yingira mu SACCO',
      AppLocale.sw: 'Jiunge na SACCO',
    },
    'tip_join_sacco_desc': {
      AppLocale.en: 'Group savings help you access loans and support',
      AppLocale.lg: 'Okuterekera awamu kuyamba okufuna ebbanja n\'obuyambi',
      AppLocale.sw: 'Akiba ya kikundi hukusaidia kupata mikopo na msaada',
    },

    // Jobs and skills
    'job_board': {
      AppLocale.en: 'Job Board',
      AppLocale.lg: 'Olukalala lw\'emirimu',
      AppLocale.sw: 'Ubao wa Kazi',
    },
    'recent_opportunities': {
      AppLocale.en: 'Recent Opportunities',
      AppLocale.lg: 'Emikisa emipya',
      AppLocale.sw: 'Fursa za Karibuni',
    },
    'jobs_near_you': {
      AppLocale.en: 'Jobs and gigs near you',
      AppLocale.lg: 'Emirimu n\'obukodyo ebiri kumpi naawe',
      AppLocale.sw: 'Kazi na ajira ndogo karibu nawe',
    },
    'build_your_cv': {
      AppLocale.en: 'Build Your CV',
      AppLocale.lg: 'Kola CV yo',
      AppLocale.sw: 'Tengeneza CV Yako',
    },
    'create_professional_profile': {
      AppLocale.en: 'Create a professional profile',
      AppLocale.lg: 'Kola ebikukwatako eby\'omulimu',
      AppLocale.sw: 'Tengeneza wasifu wa kitaaluma',
    },
    'jobs_hero_title': {
      AppLocale.en: 'Find your next opportunity',
      AppLocale.lg: 'Noonya omukisa gwo oguddako',
      AppLocale.sw: 'Pata fursa yako inayofuata',
    },
    'jobs_hero_desc': {
      AppLocale.en:
          'Browse jobs, freelance gigs, and training programmes from verified employers.',
      AppLocale.lg:
          'Noonya emirimu, obukodyo, n\'okutendekebwa okuva ku bakama b\'emirimu abakakasiddwa.',
      AppLocale.sw:
          'Vinjari kazi, kazi za muda, na mafunzo kutoka kwa waajiri waliothibitishwa.',
    },
    'job_community_health_worker': {
      AppLocale.en: 'Community Health Worker',
      AppLocale.lg: 'Omukozi w\'obulamu mu kitundu',
      AppLocale.sw: 'Mhudumu wa Afya Jamii',
    },
    'job_ngo_partner_kampala': {
      AppLocale.en: 'NGO Partner - Kampala',
      AppLocale.lg: 'Munnaffe wa NGO - Kampala',
      AppLocale.sw: 'Mshirika wa NGO - Kampala',
    },
    'job_type_full_time': {
      AppLocale.en: 'Full-time',
      AppLocale.lg: 'Obudde bwonna',
      AppLocale.sw: 'Muda wote',
    },
    'job_digital_marketing_assistant': {
      AppLocale.en: 'Digital Marketing Assistant',
      AppLocale.lg: 'Omuyambi w\'okutunda ku mutimbagano',
      AppLocale.sw: 'Msaidizi wa Masoko ya Kidijitali',
    },
    'job_tech_hub_remote': {
      AppLocale.en: 'Tech Hub - Remote',
      AppLocale.lg: 'Tech Hub - okukolera ewala',
      AppLocale.sw: 'Tech Hub - mbali',
    },
    'job_type_part_time': {
      AppLocale.en: 'Part-time',
      AppLocale.lg: 'Obudde obutono',
      AppLocale.sw: 'Muda wa sehemu',
    },
    'job_agri_extension_officer': {
      AppLocale.en: 'Agricultural Extension Officer',
      AppLocale.lg: 'Omukugu w\'okuyamba abalimi',
      AppLocale.sw: 'Afisa Ugani wa Kilimo',
    },
    'job_district_gov_mbale': {
      AppLocale.en: 'District Gov - Mbale',
      AppLocale.lg: 'Gavumenti y\'ekitundu - Mbale',
      AppLocale.sw: 'Serikali ya Wilaya - Mbale',
    },
    'job_type_contract': {
      AppLocale.en: 'Contract',
      AppLocale.lg: 'Endagaano',
      AppLocale.sw: 'Mkataba',
    },
    'job_tailoring_trainer': {
      AppLocale.en: 'Tailoring Trainer',
      AppLocale.lg: 'Omutendesi w\'okutunga engoye',
      AppLocale.sw: 'Mkufunzi wa Ushonaji',
    },
    'job_womens_centre_jinja': {
      AppLocale.en: 'Women\'s Centre - Jinja',
      AppLocale.lg: 'Ekifo ky\'abakazi - Jinja',
      AppLocale.sw: 'Kituo cha Wanawake - Jinja',
    },
    'cv_builder': {
      AppLocale.en: 'CV Builder',
      AppLocale.lg: 'Omukola CV',
      AppLocale.sw: 'Mtengenezaji wa CV',
    },
    'cv_builder_desc': {
      AppLocale.en:
          'Create a professional CV that highlights your skills and experience. AI-assisted - just answer a few questions.',
      AppLocale.lg:
          'Kola CV ey\'omulimu eraga obukugu n\'obumanyirivu bwo. AI ekuyamba - ddamu ebibuuzo bitono.',
      AppLocale.sw:
          'Tengeneza CV ya kitaaluma inayoonyesha ujuzi na uzoefu wako. AI itakusaidia - jibu maswali machache.',
    },
    'create_cv': {
      AppLocale.en: 'Create CV',
      AppLocale.lg: 'Kola CV',
      AppLocale.sw: 'Tengeneza CV',
    },
    'skills_training': {
      AppLocale.en: 'Skills & Training',
      AppLocale.lg: 'Obukugu n\'okutendekebwa',
      AppLocale.sw: 'Ujuzi na Mafunzo',
    },
    'training_programmes': {
      AppLocale.en: 'Training Programmes',
      AppLocale.lg: 'Enteekateeka z\'okutendekebwa',
      AppLocale.sw: 'Programu za Mafunzo',
    },
    'upskill_structured_courses': {
      AppLocale.en: 'Upskill with structured courses',
      AppLocale.lg: 'Yongera obukugu n\'amasomo agategekeddwa',
      AppLocale.sw: 'Ongeza ujuzi kwa kozi zilizopangwa',
    },
    'digital_literacy': {
      AppLocale.en: 'Digital Literacy',
      AppLocale.lg: 'Okumanya eby\'ekikompyuta',
      AppLocale.sw: 'Elimu ya Kidijitali',
    },
    'digital_literacy_desc': {
      AppLocale.en: 'Phone, internet, and computer basics',
      AppLocale.lg: 'Essimu, yintaneeti, n\'ebisookerwako ku kompyuta',
      AppLocale.sw: 'Misingi ya simu, intaneti, na kompyuta',
    },
    'business_management': {
      AppLocale.en: 'Business Management',
      AppLocale.lg: 'Okuddukanya obusubuzi',
      AppLocale.sw: 'Usimamizi wa Biashara',
    },
    'business_management_desc': {
      AppLocale.en: 'Planning, accounting, and operations',
      AppLocale.lg:
          'Okuteekateeka, okubala ensimbi, n\'emirimu gya buli lunaku',
      AppLocale.sw: 'Mipango, uhasibu, na uendeshaji',
    },
    'value_addition': {
      AppLocale.en: 'Value Addition',
      AppLocale.lg: 'Okwongera omuwendo',
      AppLocale.sw: 'Kuongeza Thamani',
    },
    'value_addition_desc': {
      AppLocale.en: 'Processing, packaging, and branding products',
      AppLocale.lg: 'Okukola, okupakinga, n\'okuteeka akabonero ku bintu',
      AppLocale.sw: 'Usindikaji, ufungaji, na chapa ya bidhaa',
    },
    'communication_skills': {
      AppLocale.en: 'Communication Skills',
      AppLocale.lg: 'Obukugu bw\'okwogera',
      AppLocale.sw: 'Ujuzi wa Mawasiliano',
    },
    'communication_skills_desc': {
      AppLocale.en: 'Negotiation, presentation, and networking',
      AppLocale.lg: 'Okuteesa, okunnyonnyola, n\'okukolagana n\'abalala',
      AppLocale.sw: 'Majadiliano, uwasilishaji, na kujenga mitandao',
    },
    'skills_hero_title': {
      AppLocale.en: 'Build future-ready skills',
      AppLocale.lg: 'Zimba obukugu obw\'omu maaso',
      AppLocale.sw: 'Jenga ujuzi wa maisha ya baadaye',
    },
    'skills_hero_desc': {
      AppLocale.en:
          'Practical training programmes to boost your career and business.',
      AppLocale.lg:
          'Okutendekebwa okukozesebwa okukulaakulanya omulimu n\'obusubuzi bwo.',
      AppLocale.sw: 'Mafunzo ya vitendo ya kukuza kazi na biashara yako.',
    },

    // Community, wellbeing, and profile
    'your_groups': {
      AppLocale.en: 'Your Groups',
      AppLocale.lg: 'Ebibiina byo',
      AppLocale.sw: 'Vikundi Vyako',
    },
    'your_groups_desc': {
      AppLocale.en: 'Communities you belong to',
      AppLocale.lg: 'Ebibiina by\'olimu',
      AppLocale.sw: 'Jamii unazoshiriki',
    },
    'discover_groups': {
      AppLocale.en: 'Discover Groups',
      AppLocale.lg: 'Zuula ebibiina',
      AppLocale.sw: 'Gundua Vikundi',
    },
    'discover_groups_desc': {
      AppLocale.en: 'Join women\'s groups in your area',
      AppLocale.lg: 'Yingira mu bibiina by\'abakazi mu kitundu kyo',
      AppLocale.sw: 'Jiunge na vikundi vya wanawake eneo lako',
    },
    'community_feed': {
      AppLocale.en: 'Community Feed',
      AppLocale.lg: 'Ebiwandiiko by\'ekibiina',
      AppLocale.sw: 'Habari za Jamii',
    },
    'community_feed_desc': {
      AppLocale.en: 'Latest from women in your network',
      AppLocale.lg: 'Ebisinga obupya okuva ku bakazi b\'omanyi',
      AppLocale.sw: 'Mapya kutoka kwa wanawake kwenye mtandao wako',
    },
    'community_hero_title': {
      AppLocale.en: 'Stronger together',
      AppLocale.lg: 'Tuba ba maanyi nga tuli wamu',
      AppLocale.sw: 'Tuna nguvu tukiwa pamoja',
    },
    'community_hero_desc': {
      AppLocale.en:
          'Connect with women\'s groups, share experiences, support each other, and grow together.',
      AppLocale.lg:
          'Kolagana n\'ebibiina by\'abakazi, mugabane obumanyirivu, muyambagane, era mukule wamu.',
      AppLocale.sw:
          'Ungana na vikundi vya wanawake, shiriki uzoefu, saidianeni, na kueni pamoja.',
    },
    'no_groups_yet': {
      AppLocale.en: 'No groups yet',
      AppLocale.lg: 'Tonnaba na bibiina',
      AppLocale.sw: 'Hakuna vikundi bado',
    },
    'join_or_create_group': {
      AppLocale.en: 'Join a group below or create your own',
      AppLocale.lg: 'Yingira mu kibiina wansi oba okole ekikyo',
      AppLocale.sw: 'Jiunge na kikundi hapa chini au tengeneza chako',
    },
    'create_group': {
      AppLocale.en: 'Create a Group',
      AppLocale.lg: 'Kola ekibiina',
      AppLocale.sw: 'Tengeneza Kikundi',
    },
    'members': {
      AppLocale.en: 'members',
      AppLocale.lg: 'abali mu kibiina',
      AppLocale.sw: 'wanachama',
    },
    'join': {
      AppLocale.en: 'Join',
      AppLocale.lg: 'Yingira',
      AppLocale.sw: 'Jiunge',
    },
    'group_kampala_women_entrepreneurs': {
      AppLocale.en: 'Kampala Women Entrepreneurs',
      AppLocale.lg: 'Abakazi Abasuubuzi ba Kampala',
      AppLocale.sw: 'Wajasiriamali Wanawake wa Kampala',
    },
    'group_digital_skills_network': {
      AppLocale.en: 'Digital Skills Network',
      AppLocale.lg: 'Omukutu gw\'Obukugu bw\'Ekikompyuta',
      AppLocale.sw: 'Mtandao wa Ujuzi wa Kidijitali',
    },
    'group_farmers_united': {
      AppLocale.en: 'Farmers United',
      AppLocale.lg: 'Abalimi Abegasse',
      AppLocale.sw: 'Wakulima Pamoja',
    },
    'group_young_mothers_support': {
      AppLocale.en: 'Young Mothers Support',
      AppLocale.lg: 'Obuyambi eri bamaama abato',
      AppLocale.sw: 'Msaada kwa Akina Mama Vijana',
    },
    'post_digital_skills_done': {
      AppLocale.en:
          'Just completed the Digital Skills course! So proud of this journey.',
      AppLocale.lg:
          'Mmaze okusoma Digital Skills! Nneesimye nnyo olw\'olugendo luno.',
      AppLocale.sw:
          'Nimemaliza kozi ya Ujuzi wa Kidijitali! Najivunia safari hii.',
    },
    'post_wholesale_order': {
      AppLocale.en:
          'My basket-weaving business got its first wholesale order today!',
      AppLocale.lg:
          'Obusubuzi bwange obw\'okusiba ebibbo bufunye oda yaabwo esooka leero!',
      AppLocale.sw:
          'Biashara yangu ya kusuka vikapu imepata oda yake ya kwanza ya jumla leo!',
    },
    'post_sacco_gulu': {
      AppLocale.en:
          'Looking for women interested in forming a SACCO in Gulu district.',
      AppLocale.lg:
          'Nnoonya abakazi abaagala okukola SACCO mu disitulikiti y\'e Gulu.',
      AppLocale.sw:
          'Natafuta wanawake wanaopenda kuanzisha SACCO katika wilaya ya Gulu.',
    },
    'time_2_hours_ago': {
      AppLocale.en: '2 hours ago',
      AppLocale.lg: 'essaawa 2 eziyise',
      AppLocale.sw: 'saa 2 zilizopita',
    },
    'time_5_hours_ago': {
      AppLocale.en: '5 hours ago',
      AppLocale.lg: 'essaawa 5 eziyise',
      AppLocale.sw: 'saa 5 zilizopita',
    },
    'time_1_day_ago': {
      AppLocale.en: '1 day ago',
      AppLocale.lg: 'olunaku 1 oluyise',
      AppLocale.sw: 'siku 1 iliyopita',
    },
    'like': {
      AppLocale.en: 'Like',
      AppLocale.lg: 'Njagala',
      AppLocale.sw: 'Penda',
    },
    'comment': {
      AppLocale.en: 'Comment',
      AppLocale.lg: 'Wandiika',
      AppLocale.sw: 'Toa maoni',
    },
    'share': {
      AppLocale.en: 'Share',
      AppLocale.lg: 'Gabana',
      AppLocale.sw: 'Shiriki',
    },
    'self_care': {
      AppLocale.en: 'Self-Care',
      AppLocale.lg: 'Okwefaako',
      AppLocale.sw: 'Kujitunza',
    },
    'self_care_desc': {
      AppLocale.en: 'Daily practices for a healthier mind',
      AppLocale.lg: 'Ebikolwa bya buli lunaku olw\'omutima omulamu',
      AppLocale.sw: 'Mazoea ya kila siku kwa akili yenye afya',
    },
    'stress_management': {
      AppLocale.en: 'Stress Management',
      AppLocale.lg: 'Okulabirira situleesi',
      AppLocale.sw: 'Kudhibiti Msongo',
    },
    'stress_management_desc': {
      AppLocale.en: 'Techniques to manage daily stress and anxiety',
      AppLocale.lg: 'Enkola z\'okukendeeza situleesi n\'okweraliikirira',
      AppLocale.sw: 'Mbinu za kudhibiti msongo na wasiwasi wa kila siku',
    },
    'positive_affirmations': {
      AppLocale.en: 'Positive Affirmations',
      AppLocale.lg: 'Ebigambo ebikuzzaamu amaanyi',
      AppLocale.sw: 'Maneno ya Kutia Moyo',
    },
    'positive_affirmations_desc': {
      AppLocale.en: 'Daily encouragement and confidence building',
      AppLocale.lg: 'Okuzzamu amaanyi n\'okwezimba buli lunaku',
      AppLocale.sw: 'Kutiana moyo na kujenga kujiamini kila siku',
    },
    'support_resources': {
      AppLocale.en: 'Support Resources',
      AppLocale.lg: 'Ebifo by\'obuyambi',
      AppLocale.sw: 'Rasilimali za Msaada',
    },
    'support_resources_desc': {
      AppLocale.en: 'Helplines, counselling, and safe spaces',
      AppLocale.lg: 'Ennamba z\'obuyambi, okubuulirirwa, n\'ebifo ebyesigika',
      AppLocale.sw: 'Namba za msaada, ushauri, na sehemu salama',
    },
    'wellbeing_hero_title': {
      AppLocale.en: 'Your wellbeing matters',
      AppLocale.lg: 'Embeera yo ennungi nkulu',
      AppLocale.sw: 'Ustawi wako ni muhimu',
    },
    'wellbeing_hero_desc': {
      AppLocale.en:
          'Resources for self-care, emotional support, and building resilience.',
      AppLocale.lg: 'Ebikozesebwa okwefaako, obuyambi bw\'omutima, n\'okuguma.',
      AppLocale.sw:
          'Rasilimali za kujitunza, msaada wa kihisia, na kujenga uimara.',
    },
    'safety_support': {
      AppLocale.en: 'Safety & Support',
      AppLocale.lg: 'Obukuumi n\'Obuyambi',
      AppLocale.sw: 'Usalama na Msaada',
    },
    'safety_support_desc': {
      AppLocale.en:
          'If you or someone you know needs help, trusted support is available.',
      AppLocale.lg:
          'Bw\'oba ggwe oba gw\'omanyi yeetaaga obuyambi, waliwo obuyambi obwesigika.',
      AppLocale.sw:
          'Kama wewe au mtu unayemjua anahitaji msaada, msaada wa kuaminika upo.',
    },
    'get_help': {
      AppLocale.en: 'Get Help',
      AppLocale.lg: 'Funa Obuyambi',
      AppLocale.sw: 'Pata Msaada',
    },
    'immediate_danger_help': {
      AppLocale.en:
          'If you are in immediate danger, contact emergency services now.',
      AppLocale.lg:
          'Bw\'oba oli mu kabi akatali ka kulinda, tuukirira empeereza z\'obudduukirize kati.',
      AppLocale.sw:
          'Kama uko hatarini sasa, wasiliana na huduma za dharura mara moja.',
    },
    'helpline_police': {
      AppLocale.en: 'Uganda Police Emergency',
      AppLocale.lg: 'Uganda Police Emergency',
      AppLocale.sw: 'Dharura ya Polisi Uganda',
    },
    'helpline_police_desc': {
      AppLocale.en: 'For immediate danger or a safety emergency',
      AppLocale.lg: 'Ku kabi akatali ka kulinda oba ensonga y\'obukuumi',
      AppLocale.sw: 'Kwa hatari ya haraka au dharura ya usalama',
    },
    'helpline_emergency_alt': {
      AppLocale.en: 'Uganda Emergency Services (alt.)',
      AppLocale.lg: 'Empeereza z\'obudduukirize eza Uganda (endala)',
      AppLocale.sw: 'Huduma za Dharura Uganda (nyingine)',
    },
    'helpline_emergency_alt_desc': {
      AppLocale.en: 'Alternate national emergency line',
      AppLocale.lg: 'Ennamba endala ey\'obudduukirize mu ggwanga',
      AppLocale.sw: 'Namba nyingine ya dharura ya kitaifa',
    },
    'helpline_trusted_person': {
      AppLocale.en: 'Talk to someone you trust',
      AppLocale.lg: 'Yogera n\'omuntu gwe weesiga',
      AppLocale.sw: 'Zungumza na mtu unayemwamini',
    },
    'helpline_trusted_person_desc': {
      AppLocale.en:
          'A family member, friend, or community leader can help you find local support even when a hotline is not available.',
      AppLocale.lg:
          'Ow\'omu maka, mukwano, oba omukulembeze w\'ekitundu ayinza okukuyamba okufuna obuyambi obuli okumpi.',
      AppLocale.sw:
          'Mwanafamilia, rafiki, au kiongozi wa jamii anaweza kukusaidia kupata msaada wa karibu.',
    },
    'my_profile': {
      AppLocale.en: 'My Profile',
      AppLocale.lg: 'Ebikwata ku nze',
      AppLocale.sw: 'Wasifu Wangu',
    },
    'friend': {
      AppLocale.en: 'Friend',
      AppLocale.lg: 'Mukwano',
      AppLocale.sw: 'Rafiki',
    },
    'my_progress': {
      AppLocale.en: 'My Progress',
      AppLocale.lg: 'Entambula yange',
      AppLocale.sw: 'Maendeleo Yangu',
    },
    'track_learning_growth': {
      AppLocale.en: 'Track your learning and growth',
      AppLocale.lg: 'Londoola okusoma kwo n\'okukula kwo',
      AppLocale.sw: 'Fuatilia kujifunza na ukuaji wako',
    },
    'achievements': {
      AppLocale.en: 'Achievements',
      AppLocale.lg: 'By\'otuuseeko',
      AppLocale.sw: 'Mafanikio',
    },
    'badges_earned': {
      AppLocale.en: 'Badges you have earned',
      AppLocale.lg: 'Obubonero bw\'ofunye',
      AppLocale.sw: 'Beji ulizopata',
    },
    'member': {
      AppLocale.en: 'Member',
      AppLocale.lg: 'Omu ku baffe',
      AppLocale.sw: 'Mwanachama',
    },
    'location_not_set': {
      AppLocale.en: 'Location not set',
      AppLocale.lg: 'Ekifo tekinnateekebwawo',
      AppLocale.sw: 'Mahali hapajawekwa',
    },
    'days': {
      AppLocale.en: 'days',
      AppLocale.lg: 'ennaku',
      AppLocale.sw: 'siku',
    },
    'badges': {
      AppLocale.en: 'Badges',
      AppLocale.lg: 'Obubonero',
      AppLocale.sw: 'Beji',
    },
    'badge_first_step': {
      AppLocale.en: 'First Step',
      AppLocale.lg: 'Omutendera Ogusooka',
      AppLocale.sw: 'Hatua ya Kwanza',
    },
    'badge_quick_learner': {
      AppLocale.en: 'Quick Learner',
      AppLocale.lg: 'Ayiga Mangu',
      AppLocale.sw: 'Mwanafunzi Mwepesi',
    },
    'badge_community_star': {
      AppLocale.en: 'Community Star',
      AppLocale.lg: 'Emmunyeenye y\'Ekibiina',
      AppLocale.sw: 'Nyota wa Jamii',
    },
    'badge_entrepreneur': {
      AppLocale.en: 'Entrepreneur',
      AppLocale.lg: 'Omusubuzi',
      AppLocale.sw: 'Mjasiriamali',
    },
    'badge_consistent': {
      AppLocale.en: 'Consistent',
      AppLocale.lg: 'Atalekera awo',
      AppLocale.sw: 'Mwenye Uthabiti',
    },
    'mentor_agriculture_business': {
      AppLocale.en: 'Agriculture & Agribusiness',
      AppLocale.lg: 'Obulimi n\'obusubuzi bw\'ebyobulimi',
      AppLocale.sw: 'Kilimo na Biashara ya Kilimo',
    },
    'mentor_financial_management': {
      AppLocale.en: 'Financial Management',
      AppLocale.lg: 'Okuddukanya ensimbi',
      AppLocale.sw: 'Usimamizi wa Fedha',
    },
    'mentor_digital_marketing': {
      AppLocale.en: 'Digital Marketing',
      AppLocale.lg: 'Okutunda ku mutimbagano',
      AppLocale.sw: 'Masoko ya Kidijitali',
    },
    'facility_nakasero_hospital': {
      AppLocale.en: 'Nakasero Hospital',
      AppLocale.lg: 'Eddwaliro lya Nakasero',
      AppLocale.sw: 'Hospitali ya Nakasero',
    },
    'facility_mulago_womens_clinic': {
      AppLocale.en: 'Mulago Women\'s Clinic',
      AppLocale.lg: 'Kiliniiki y\'Abakazi e Mulago',
      AppLocale.sw: 'Kliniki ya Wanawake Mulago',
    },
    'facility_community_health_post': {
      AppLocale.en: 'Community Health Post',
      AppLocale.lg: 'Ekifo ky\'obulamu mu kitundu',
      AppLocale.sw: 'Kituo cha Afya Jamii',
    },
    'facility_type_health_centre_iv': {
      AppLocale.en: 'Health Centre IV',
      AppLocale.lg: 'Health Centre IV',
      AppLocale.sw: 'Kituo cha Afya IV',
    },
    'facility_type_specialised': {
      AppLocale.en: 'Specialised',
      AppLocale.lg: 'Eky\'obukugu',
      AppLocale.sw: 'Maalum',
    },
    'facility_type_health_centre_ii': {
      AppLocale.en: 'Health Centre II',
      AppLocale.lg: 'Health Centre II',
      AppLocale.sw: 'Kituo cha Afya II',
    },
    'could_not_load_listings': {
      AppLocale.en: 'Could not load listings',
      AppLocale.lg: 'Tetwasobodde okutikka ebintu',
      AppLocale.sw: 'Imeshindwa kupakia orodha',
    },

    'powered_by_groq': {
      AppLocale.en: 'Powered by Groq · Llama 3.3',
      AppLocale.lg: 'Yakozesebwa Groq · Llama 3.3',
      AppLocale.sw: 'Inayotumia Groq · Llama 3.3',
    },
    'ai_greeting': {
      AppLocale.en:
          'Hello! I\'m your AI assistant from AI Connect Africa. I can help you with business advice, farming tips, health information, financial guidance, and much more. What would you like to know?',
      AppLocale.lg:
          'Oli otya! Nze omuyambi wo wa AI okuva ku AI Connect Africa. Nsobola okukuyamba n\'amagezi g\'obusubuzi, ebyobulimi, amakwate g\'obulamu, ebiragiro by\'ensimbi, n\'ebirala bingi. Oyagala okumanya ki?',
      AppLocale.sw:
          'Habari! Mimi ni msaidizi wako wa AI kutoka AI Connect Africa. Ninaweza kukusaidia na ushauri wa biashara, vidokezo vya kilimo, habari za afya, mwongozo wa fedha, na mengi zaidi. Ungependa kujua nini?',
    },
    'chat_cleared': {
      AppLocale.en: 'Chat cleared! How can I help you?',
      AppLocale.lg: 'Emboozi esaziddwa! Nsobola kukuyamba otya?',
      AppLocale.sw: 'Mazungumzo yamesafishwa! Ninawezaje kukusaidia?',
    },
    'chat_send': {
      AppLocale.en: 'Send message',
      AppLocale.lg: 'Weereza obubaka',
      AppLocale.sw: 'Tuma ujumbe',
    },
    'chat_retry': {
      AppLocale.en: 'Retry',
      AppLocale.lg: 'Gezaako nate',
      AppLocale.sw: 'Jaribu tena',
    },
    'chat_connection_error': {
      AppLocale.en:
          'We couldn’t connect to the assistant. Please try again shortly.',
      AppLocale.lg:
          'Wabaddewo obuzibu mu kuyungibwa ku muyambi. Gezaako nate mu kaseera katono.',
      AppLocale.sw:
          'Kumetokea tatizo la kuunganisha na msaidizi. Tafadhali jaribu tena baada ya muda mfupi.',
    },
    'chat_offline_error': {
      AppLocale.en: 'Check your internet connection and try again.',
      AppLocale.lg: 'Kebera omukutu gwo ogwa yintaneeti, oddemu ogezeeko.',
      AppLocale.sw: 'Angalia muunganisho wako wa intaneti kisha ujaribu tena.',
    },
    'chat_authentication_error': {
      AppLocale.en: 'The assistant is temporarily unavailable.',
      AppLocale.lg: 'Omuyambi taliko mu kiseera kino.',
      AppLocale.sw: 'Msaidizi hapatikani kwa sasa.',
    },
    'topic_business_q': {
      AppLocale.en: 'How do I start a small business?',
      AppLocale.lg: 'Ndinda otya obusubuzi obuto?',
      AppLocale.sw: 'Ninawezaje kuanzisha biashara ndogo?',
    },
    'topic_savings_q': {
      AppLocale.en: 'Tips for saving money',
      AppLocale.lg: 'Amagezi g\'okuterekawo ensimbi',
      AppLocale.sw: 'Vidokezo vya kuweka akiba',
    },
    'topic_farming_q': {
      AppLocale.en: 'Best crops for my region',
      AppLocale.lg: 'Ebimera ebirungi mu kitundu kyange',
      AppLocale.sw: 'Mazao bora kwa eneo langu',
    },
    'topic_sell_online_q': {
      AppLocale.en: 'How to sell online',
      AppLocale.lg: 'Otunda otya ku mutimbagano',
      AppLocale.sw: 'Jinsi ya kuuza mtandaoni',
    },
  };
}
