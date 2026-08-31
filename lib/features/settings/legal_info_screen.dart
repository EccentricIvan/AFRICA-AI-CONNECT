import 'package:flutter/material.dart';

/// Plain in-app info screen used by both the Terms of Service and Privacy
/// Policy tiles in Settings. There's no hosted legal document yet — this is
/// an honest, practical summary of what the app actually does with data,
/// not a substitute for real drafted legal copy. Point these tiles at a
/// real hosted policy once one exists.
class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  static const privacyBody =
      'This app stores your profile (name, role, location) and phone '
      "number locally on your device, and mirrors it to your account in "
      "the cloud so it's available if you sign in on another device.\n\n"
      'Marketplace listings, mentor connections, job applications, '
      'community groups, and messages you send are stored locally on '
      'this device. They are not currently synced to any other device.\n\n'
      'Nothing you enter is shared with advertisers or sold to third '
      "parties. Chat questions the offline assistant can't answer may be "
      "looked up from public sources (Wikipedia, DuckDuckGo) when you're "
      'online.\n\n'
      'Use "Sign out" in Settings to clear this device\'s local data '
      'before handing the phone to someone else.';

  static const termsBody =
      'This app is provided to help you learn, earn, grow, and connect '
      "with your community. Use it in good faith — don't post false "
      'listings, impersonate someone else, or use the messaging features '
      'to harass other users.\n\n'
      'Content you post (marketplace listings, community posts, '
      "messages) is your responsibility. The app's offline AI assistant "
      'gives general guidance, not professional legal, medical, or '
      'financial advice — for anything urgent, contact a trusted local '
      'professional or emergency service.\n\n'
      'A full legal Terms of Service is being finalized; this page will '
      'be updated with a link to it once published.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(body, style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        ),
      ),
    );
  }
}
