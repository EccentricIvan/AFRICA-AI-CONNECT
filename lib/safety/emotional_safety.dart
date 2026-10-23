/// Offline emotional safety engine.
///
/// Scans student messages for signs of emotional distress before they
/// reach the tutor pipeline. Everything runs on-device — no network,
/// no external moderation APIs.
///
/// Three levels of concern:
///   frustration → student is discouraged; tutor should encourage
///   distress    → bullying/fear/sadness; tutor responds with empathy first
///   crisis      → self-harm signals; bypass the LLM entirely and show a
///                 fixed supportive message pointing to a trusted adult
library;

enum SafetyConcern { none, frustration, distress, crisis }

class SafetyCheckResult {
  const SafetyCheckResult({
    required this.concern,
    this.supportMessage,
    this.tutorNote,
  });

  final SafetyConcern concern;

  /// Fixed message shown INSTEAD of an LLM response (crisis only).
  final String? supportMessage;

  /// Instruction injected into the tutor prompt (frustration/distress).
  final String? tutorNote;

  bool get bypassTutor => concern == SafetyConcern.crisis;
}

class EmotionalSafetyEngine {
  const EmotionalSafetyEngine();

  // Crisis: never answered by the model. Conservative — better to show a
  // caring fixed message unnecessarily than to let the model improvise.
  static final _crisisPatterns = <RegExp>[
    RegExp(r'\b(kill|hurt|harm)\s+(myself|my\s*self)\b', caseSensitive: false),
    RegExp(r"\b(want|wish)\s+to\s+(die|disappear|not exist)\b", caseSensitive: false),
    RegExp(r'\bsuicid', caseSensitive: false),
    RegExp(r'\bself[\s-]?harm', caseSensitive: false),
    RegExp(r'\bend\s+my\s+life\b', caseSensitive: false),
    RegExp(r"\bno\s+reason\s+to\s+live\b", caseSensitive: false),
    RegExp(r"\b(don'?t|do\s+not)\s+want\s+to\s+(live|be\s+alive)\b", caseSensitive: false),
    RegExp(r'\btake\s+my\s+(own\s+)?life\b', caseSensitive: false),
    RegExp(r'\bbetter\s+off\s+dead\b', caseSensitive: false),
  ];

  static final _distressPatterns = <RegExp>[
    RegExp(r'\b(bully|bullied|bullying)\b', caseSensitive: false),
    RegExp(r'\b(beat|beats|hits?|hitting)\s+me\b', caseSensitive: false),
    RegExp(r'\bscared\s+of\b', caseSensitive: false),
    RegExp(r'\b(nobody|no one)\s+(likes|loves|cares about)\s+me\b', caseSensitive: false),
    RegExp(r'\b(always|so)\s+(sad|alone|lonely)\b', caseSensitive: false),
    RegExp(r'\bcry(ing)?\s+(every|all)\b', caseSensitive: false),
    RegExp(r'\bhate\s+my\s+life\b', caseSensitive: false),
  ];

  static final _frustrationPatterns = <RegExp>[
    RegExp(r"\bi\s+(give|gave)\s+up\b", caseSensitive: false),
    RegExp(r"\bi('?m| am)\s+(so\s+)?(stupid|dumb|useless|worthless)\b", caseSensitive: false),
    RegExp(r"\bi\s+(can'?t|cannot)\s+do\s+(this|it|anything)\b", caseSensitive: false),
    RegExp(r'\btoo\s+hard\s+for\s+me\b', caseSensitive: false),
    RegExp(r"\bi('?ll| will)\s+never\s+(understand|learn|get)\b", caseSensitive: false),
    RegExp(r'\bhate\s+(this|school|maths?|studying)\b', caseSensitive: false),
  ];

  // Uganda numbers: Sauti 116 is the free 24-hour child helpline; 999 and
  // 112 reach police and emergency services.
  static const _crisisMessage =
      "Thank you for telling me how you feel — that takes real courage. "
      "What you're feeling matters, and you don't have to carry it alone.\n\n"
      "Here are things you can do right now:\n"
      "• Tell someone you trust today: a parent, a teacher, the school "
      "nurse or counsellor, a religious leader, or another adult who cares "
      "about you. You can simply say: \"I am not okay and I need help.\"\n"
      "• Call Sauti, the free child helpline, on 116. It is free from any "
      "phone, open day and night, and they will listen.\n"
      "• If you are in danger now or might hurt yourself, call 999 or 112, "
      "or go to the nearest health centre or hospital.\n"
      "• Stay near other people, and move away from anything you could use "
      "to hurt yourself.\n"
      "• Breathe slowly: in for 4, hold for 4, out for 4. Do it a few times. "
      "Strong feelings like this can pass, and help really does work.\n\n"
      "You are important, and people want to help you. I'll be right here "
      "whenever you want to learn together again. 💚";

  SafetyCheckResult check(String message) {
    for (final p in _crisisPatterns) {
      if (p.hasMatch(message)) {
        return const SafetyCheckResult(
          concern: SafetyConcern.crisis,
          supportMessage: _crisisMessage,
        );
      }
    }

    for (final p in _distressPatterns) {
      if (p.hasMatch(message)) {
        return const SafetyCheckResult(
          concern: SafetyConcern.distress,
          tutorNote:
              'IMPORTANT: The student may be experiencing distress (sadness, '
              'bullying, or fear). Respond with warmth and empathy FIRST. '
              'Acknowledge their feelings before any teaching. Gently suggest '
              'talking to a trusted teacher or adult. Do not lecture.',
        );
      }
    }

    for (final p in _frustrationPatterns) {
      if (p.hasMatch(message)) {
        return const SafetyCheckResult(
          concern: SafetyConcern.frustration,
          tutorNote:
              'IMPORTANT: The student sounds discouraged or frustrated. '
              'Start by encouraging them — remind them that struggling is a '
              'normal part of learning. Then make your explanation simpler '
              'and smaller than usual. Celebrate any effort they have made.',
        );
      }
    }

    return const SafetyCheckResult(concern: SafetyConcern.none);
  }
}
