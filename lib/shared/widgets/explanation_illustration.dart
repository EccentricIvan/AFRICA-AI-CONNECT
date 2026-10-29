import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_core/online/online_tutor.dart';
import '../../curriculum/online_topic_lookup.dart';
import '../../curriculum/topic_explanations.dart';
import '../../l10n/app_locale.dart';
import '../../safety/emotional_safety.dart';
import 'curriculum_diagram.dart';

class ExplanationPicture {
  const ExplanationPicture({
    required this.path,
    required this.subject,
    required this.guidance,
    required this.credit,
  });
  final String path;
  final String subject;
  final String guidance;
  final String credit;
}

/// Resolve a teaching visual separately from answer generation. Existing local
/// diagrams win; a missed picture never delays or replaces the text answer.
Future<ExplanationPicture?> findExplanationPicture(
  String question, {
  required Future<TopicExplanation?> Function(String) local,
  Future<List<WebPicture>> Function(String)? hub,
  Future<List<WebPicture>> Function(String)? internet,
}) async {
  if (const EmotionalSafetyEngine().check(question).concern !=
      SafetyConcern.none) {
    return null;
  }
  var subject = askedTopic(question);
  if (subject == null) {
    final example = RegExp(
      r'^(?:give|show) me (?:an? )?(?:worked )?examples? (?:of|about|on) (.+)',
      caseSensitive: false,
    ).firstMatch(question.trim());
    subject = example?.group(1)?.replaceFirst(RegExp(r'[?.!]+$'), '').trim();
  }
  if (subject == null) {
    final match = RegExp(
      r'^(?:how|why) (?:does|do|is|are|can) (.+)',
      caseSensitive: false,
    ).firstMatch(question.trim());
    subject = match?.group(1)?.replaceFirst(RegExp(r'[?.!]+$'), '').trim();
  }
  if (subject == null ||
      subject.isEmpty ||
      subject.length > 100 ||
      RegExp(r'^(it|this|that|them|they|he|she)$').hasMatch(subject)) {
    return null;
  }
  try {
    final diagram = await local(subject);
    if (diagram?.diagram != null) {
      final photosynthesis = subject.toLowerCase().contains('photosynth');
      final nutrition = RegExp(
        r'nutrition|nutrient|autotroph|heterotroph',
        caseSensitive: false,
      ).hasMatch(subject);
      return ExplanationPicture(
        path: diagram!.diagram!,
        subject: subject,
        guidance: photosynthesis
            ? 'Follow the arrows: roots take in water, leaves take in carbon dioxide, '
                  'and sunlight helps the plant make sugar. Oxygen goes back into the air.'
            : nutrition
            ? 'A goat eats plant food, so it is a heterotroph. The chart separates how organisms get food from the nutrients that food contains.'
            : 'Follow the labels and arrows, and connect each part to the explanation above.',
        credit: diagram.notes
            .where((note) => note.startsWith('Diagram:'))
            .join(' '),
      );
    }
  } catch (_) {
    /* Missing assets must not block other sources. */
  }
  for (final source in [hub, internet]) {
    if (source == null) continue;
    try {
      final pictures = await source(subject);
      if (pictures.isNotEmpty) {
        final picture = pictures.first;
        return ExplanationPicture(
          path: picture.url,
          subject: subject,
          guidance: picture.caption,
          credit: picture.credit,
        );
      }
    } catch (_) {
      /* A disconnected source leaves the explanation usable. */
    }
  }
  return null;
}

/// Mounted only beside a completed reply: lookup and image decoding never hold
/// up the streamed answer. A missing visual occupies no space.
class ExplanationIllustration extends ConsumerStatefulWidget {
  const ExplanationIllustration({
    super.key,
    required this.question,
    this.resolve,
  });
  final String question;
  final Future<ExplanationPicture?> Function(String)? resolve;
  @override
  ConsumerState<ExplanationIllustration> createState() =>
      _ExplanationIllustrationState();
}

class _ExplanationIllustrationState
    extends ConsumerState<ExplanationIllustration> {
  late Future<ExplanationPicture?> _picture;
  @override
  void initState() {
    super.initState();
    _picture = _load();
  }

  @override
  void didUpdateWidget(ExplanationIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) _picture = _load();
  }

  Future<ExplanationPicture?> _load() {
    if (widget.resolve != null) return widget.resolve!(widget.question);
    final lessons = ref.read(topicExplanationServiceProvider);
    final hub = ref.read(onlineTutorProvider);
    final online = ref.read(onlineTopicLookupEnabledProvider);
    final lookup = ref.read(onlineTopicLookupProvider);
    return findExplanationPicture(
      widget.question,
      local: lessons.localPicture,
      hub: hub == null ? null : (subject) => hub.pictures(subject),
      internet: online ? (subject) => lookup.pictures(subject, max: 1) : null,
    );
  }

  void _enlarge(BuildContext context, ExplanationPicture picture) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 1000,
          height: MediaQuery.sizeOf(dialogContext).height * 0.8,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        picture.subject,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: tr(dialogContext, 'Close'),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: CurriculumDiagram(
                    assetPath: picture.path,
                    semanticLabel: picture.guidance,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(picture.guidance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ExplanationPicture?>(
    future: _picture,
    builder: (context, snapshot) {
      final picture = snapshot.data;
      if (picture == null) return const SizedBox.shrink();
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr(context, 'Picture explanation'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr(context, 'Enlarge picture'),
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () => _enlarge(context, picture),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: CurriculumDiagram(
                assetPath: picture.path,
                semanticLabel: '${picture.subject}: ${picture.guidance}',
              ),
            ),
            if (picture.guidance.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(picture.guidance),
              ),
            if (picture.credit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  picture.credit,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      );
    },
  );
}
