import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale {
  en('English', 'EN'),
  lg('Luganda', 'LG'),
  sw('Kiswahili', 'SW');

  const AppLocale(this.label, this.code);
  final String label;
  final String code;
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier([AppLocale initialLocale = AppLocale.en]) : super(initialLocale);

  static AppLocale fromSaved(String? saved) {
    return AppLocale.values.firstWhere(
      (locale) => locale.name == saved,
      orElse: () => AppLocale.en,
    );
  }

  void set(AppLocale locale) {
    state = locale;
    SharedPreferences.getInstance().then(
      (p) => p.setString('app_locale', locale.name),
    );
  }

  void loadFromPrefs(String? saved) {
    if (saved == null) return;
    for (final l in AppLocale.values) {
      if (l.name == saved) {
        state = l;
        return;
      }
    }
  }
}

class S {
  S._();

  static String tr(BuildContext context, WidgetRef ref, String key) {
    final locale = ref.watch(localeProvider);
    return _strings[key]?[locale] ?? _strings[key]?[AppLocale.en] ?? key;
  }

  static String trFromLocale(String key, AppLocale locale) {
    return _strings[key]?[locale] ?? _strings[key]?[AppLocale.en] ?? key;
  }

  static const _strings = <String, Map<AppLocale, String>>{
    // ── App-wide ──
    'app_name': {
      AppLocale.en: 'Africa AI Connect',
      AppLocale.lg: 'Africa AI Connect',
      AppLocale.sw: 'Africa AI Connect',
    },
    'app_powered_by': {
      AppLocale.en: 'Powered by Africa AI Connect',
      AppLocale.lg: 'Ekozesebwa Africa AI Connect',
      AppLocale.sw: 'Inaendeshwa na Africa AI Connect',
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
      AppLocale.en: 'Empowering your\ndigital journey',
      AppLocale.lg: 'Tukubudde mu\nntambula yo ey\'ekikompyuta',
      AppLocale.sw: 'Kuwezesha safari\nyako ya kidijitali',
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
      AppLocale.en: 'day streak!',
      AppLocale.lg: 'ennaku empita!',
      AppLocale.sw: 'siku mfululizo!',
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
      AppLocale.en: 'Welcome to\nAfrica AI Connect',
      AppLocale.lg: 'Tukusanyukira ku\nAfrica AI Connect',
      AppLocale.sw: 'Karibu kwenye\nAfrica AI Connect',
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
      AppLocale.en: 'On Windows, you may briefly see a verification step before your code is sent.',
      AppLocale.lg: 'Ku Windows, oyinza okulaba akadde ak\'okukakasa nga koodi tennasindikwa.',
      AppLocale.sw: 'Kwenye Windows, huenda ukaona hatua fupi ya uthibitisho kabla msimbo haujatumwa.',
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
      AppLocale.lg: 'Tewali kintu kyawandiikibwa — beera owasooka okuwandiika ekintu!',
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
    'chat_assistant_title': {
      AppLocale.en: 'AI Assistant',
      AppLocale.lg: 'Omuyambi wa AI',
      AppLocale.sw: 'Msaidizi wa AI',
    },
    'ai_greeting': {
      AppLocale.en:
          'Hello! I\'m your AI assistant from Africa AI Connect. I can help you with business advice, farming tips, health information, financial guidance, and much more. What would you like to know?',
      AppLocale.lg:
          'Oli otya! Nze omuyambi wo wa AI okuva ku Africa AI Connect. Nsobola okukuyamba n\'amagezi g\'obusubuzi, ebyobulimi, amakwate g\'obulamu, ebiragiro by\'ensimbi, n\'ebirala bingi. Oyagala okumanya ki?',
      AppLocale.sw:
          'Habari! Mimi ni msaidizi wako wa AI kutoka Africa AI Connect. Ninaweza kukusaidia na ushauri wa biashara, vidokezo vya kilimo, habari za afya, mwongozo wa fedha, na mengi zaidi. Ungependa kujua nini?',
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
      AppLocale.en: 'We couldn’t connect to the assistant. Please try again shortly.',
      AppLocale.lg: 'Wabaddewo obuzibu mu kuyungibwa ku muyambi. Gezaako nate mu kaseera katono.',
      AppLocale.sw: 'Kumetokea tatizo la kuunganisha na msaidizi. Tafadhali jaribu tena baada ya muda mfupi.',
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
