import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'curriculum_models.dart';
import 'curriculum_provider.dart';

/// One heading of a full topic explanation.
class ExplanationSection {
  const ExplanationSection({required this.heading, required this.body});

  final String heading;
  final String body;

  factory ExplanationSection.fromJson(Map<String, dynamic> json) =>
      ExplanationSection(
        heading: json['heading'] as String,
        body: json['body'] as String,
      );
}

/// A complete, reviewed explanation of one syllabus topic ("What is
/// photosynthesis?"), written and checked by us and shipped in a topic pack.
///
/// The tutor shows it as written the first time a learner asks for the topic,
/// so the full explanation is always correct and at the right level; the
/// model then answers follow-ups from it. Packs sit beside the bundled
/// curriculum and never change it.
class TopicExplanation {
  const TopicExplanation({
    required this.id,
    required this.subjectName,
    required this.level,
    required this.title,
    required this.version,
    required this.aliases,
    required this.summary,
    required this.sections,
    this.keyTerms = const {},
    this.diagram,
    this.video,
    this.checkQuestions = const [],
    List<String>? wholeTopicNames,
    this.lesson,
    this.notes = const [],
  }) : wholeTopicNames = wholeTopicNames ?? aliases;

  /// A curriculum lesson as a full explanation: its question-and-answer
  /// content becomes the sections, its worked examples and quiz follow. The
  /// lesson itself is unchanged and still feeds the lesson card.
  factory TopicExplanation.fromLesson(
    Lesson lesson, {
    required String subjectId,
    required String subjectName,
    required String unitTitle,
    LessonDiagram? addedDiagram,
  }) {
    // A lesson without its own diagram takes one from diagrams.json, on a
    // copy: the curriculum's lesson is never changed.
    if (lesson.diagram == null && addedDiagram != null) {
      lesson = Lesson(
        title: lesson.title,
        content: lesson.content,
        examples: lesson.examples,
        keyTerms: lesson.keyTerms,
        quiz: lesson.quiz,
        diagram: addedDiagram.asset,
      );
    } else {
      addedDiagram = null;
    }
    final (intro, sections) = _questionsAndAnswers(lesson.content);
    final names = lessonTopicNames(lesson.title);
    return TopicExplanation(
      id: '$subjectId.${names.first.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      subjectName: subjectName,
      level: unitTitle,
      title: lesson.title,
      version: 0,
      aliases: [
        ...names,
        for (final term in lesson.keyTerms.keys)
          if (term.length >= 6 || term.contains(' ')) normalizeTopicText(term),
      ],
      wholeTopicNames: names,
      summary: intro,
      sections: [
        ...sections,
        for (var i = 0; i < lesson.examples.length && i < 3; i++)
          ExplanationSection(
            heading: lesson.examples.length == 1
                ? 'Worked example'
                : 'Worked example ${i + 1}',
            body: _workedExample(lesson.examples[i]),
          ),
      ],
      keyTerms: lesson.keyTerms,
      diagram: lesson.diagram,
      checkQuestions: [
        for (final q in lesson.quiz.take(3))
          '${q.question}\n${[for (var i = 0; i < q.options.length; i++) '${String.fromCharCode(97 + i)}) ${q.options[i]}'].join('   ')}',
      ],
      lesson: lesson,
      notes: [
        if (addedDiagram != null && addedDiagram.credit.isNotEmpty)
          'Diagram: ${addedDiagram.credit}',
      ],
    );
  }

  /// Lines shown in small print at the end: picture credits, where an
  /// online explanation came from.
  final List<String> notes;

  final String id;
  final String subjectName;

  /// The class it is written for, e.g. "S2".
  final String level;
  final String title;

  /// Goes up with every reviewed change; the highest version of an id wins.
  final int version;

  /// Names a learner may use for the topic ("photosynthesis", "how plants
  /// make food"), lower case.
  final List<String> aliases;
  final String summary;
  final List<ExplanationSection> sections;
  final Map<String, String> keyTerms;

  /// Bundled SVG shown in the chat's lesson card.
  final String? diagram;

  /// Reserved for a bundled clip; the chat has no player yet.
  final String? video;
  final List<String> checkQuestions;

  /// The names that ask for the whole explanation. A curriculum lesson's key
  /// terms are in [aliases] only: "what is a variable" gets an answer
  /// grounded in the lesson, not the whole lesson.
  final List<String> wholeTopicNames;

  /// The curriculum lesson this was made from, if any.
  final Lesson? lesson;

  /// Whether this is a reviewed pack topic rather than a curriculum lesson.
  bool get fromPack => lesson == null;

  factory TopicExplanation.fromJson(
    Map<String, dynamic> json, {
    required String subjectName,
  }) => TopicExplanation(
    id: json['id'] as String,
    subjectName: subjectName,
    level: json['level'] as String? ?? '',
    title: json['title'] as String,
    version: json['version'] as int? ?? 1,
    aliases: [
      for (final a in json['aliases'] as List? ?? const []) normalizeTopicText(a as String),
    ],
    summary: json['summary'] as String,
    sections: [
      for (final s in json['sections'] as List)
        ExplanationSection.fromJson(s as Map<String, dynamic>),
    ],
    keyTerms:
        (json['keyTerms'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as String),
        ) ??
        const {},
    diagram: json['diagram'] as String?,
    video: json['video'] as String?,
    checkQuestions: [
      for (final q in json['checkQuestions'] as List? ?? const []) q as String,
    ],
  );

  /// The whole explanation as chat text (markdown headings, as the chat
  /// bubble renders them).
  String fullText() {
    final buf = StringBuffer()..writeln('**$title** ($subjectName, $level)');
    if (summary.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(summary);
    }
    for (final s in sections) {
      buf
        ..writeln()
        ..writeln('**${s.heading}**')
        ..writeln(s.body);
    }
    if (checkQuestions.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('**Check your understanding**');
      for (var i = 0; i < checkQuestions.length; i++) {
        buf.writeln('${i + 1}. ${checkQuestions[i]}');
      }
    }
    for (final n in notes) {
      buf
        ..writeln()
        ..writeln('_${n}_');
    }
    return buf.toString().trim();
  }

  /// This explanation with an online look-up's overview in front and its
  /// picture when this one has none, keeping the look-up's "not from your
  /// syllabus" note and credit.
  TopicExplanation withOnline(TopicExplanation web) => TopicExplanation(
    id: id,
    subjectName: subjectName,
    level: level,
    title: title,
    version: version,
    aliases: aliases,
    summary: summary,
    sections: [
      ExplanationSection(heading: 'Overview (from Wikipedia)', body: web.summary),
      ...sections,
    ],
    keyTerms: keyTerms,
    diagram: diagram ?? web.diagram,
    checkQuestions: checkQuestions,
    wholeTopicNames: wholeTopicNames,
    lesson: lesson,
    notes: [...notes, ...web.notes],
  );

  /// A lesson for the chat's existing lesson card, so the diagram shows
  /// with no new UI.
  Lesson asLesson() =>
      lesson ??
      Lesson(title: title, content: summary, keyTerms: keyTerms, diagram: diagram);

  /// Whether [question] asks about something this explanation covers (a
  /// word of five letters or more from it), so a follow-up that doesn't name
  /// the topic stays on it.
  bool mentions(String question) {
    final asked = {
      for (final w in _words(question))
        if (w.length >= 5) w,
    };
    if (asked.isEmpty) return false;
    final covered = _words(
      [title, ...keyTerms.keys, for (final s in sections) '${s.heading} ${s.body}'].join(' '),
    );
    return asked.intersection(covered).isNotEmpty;
  }

  /// The parts of this explanation that best fit [question], within [max]
  /// characters, for grounding a follow-up answer.
  String groundingNotes(String question, {int max = 680}) {
    final asked = _words(question);
    final ranked = [...sections]
      ..sort(
        (a, b) => _words('${b.heading} ${b.body}')
            .intersection(asked)
            .length
            .compareTo(_words('${a.heading} ${a.body}').intersection(asked).length),
      );
    final buf = StringBuffer()
      ..writeln('Subject: $subjectName ($level)')
      ..writeln('Topic: $title');
    if (keyTerms.isNotEmpty) {
      buf.writeln(
        'Definitions: ${keyTerms.entries.take(3).map((e) => '${e.key}: ${e.value}').join('; ')}',
      );
    }
    for (final s in ranked) {
      final line = '${s.heading}: ${s.body}';
      if (buf.length + line.length > max) {
        final room = max - buf.length;
        if (room > 120) buf.write('${line.substring(0, room - 1)}…');
        break;
      }
      buf.writeln(line);
    }
    return buf.toString().trim();
  }
}

/// A bundled picture for a lesson that has none, from
/// `assets/topic_explanations/diagrams.json` ("subjectId|Lesson title").
class LessonDiagram {
  const LessonDiagram({required this.asset, required this.credit});

  final String asset;

  /// Author, licence and source, shown under the explanation.
  final String credit;

  static Map<String, LessonDiagram> parseAll(String json) => {
    for (final e in (jsonDecode(json) as Map<String, dynamic>).entries)
      e.key: LessonDiagram(
        asset: (e.value as Map<String, dynamic>)['asset'] as String,
        credit: (e.value as Map<String, dynamic>)['credit'] as String,
      ),
  };
}

/// Splits lesson content written as "Question? Answer. Question? Answer." into
/// sections headed by each question, plus any text before the first one.
(String, List<ExplanationSection>) _questionsAndAnswers(String content) {
  final questions = <(int, int)>[];
  var from = 0;
  for (final m in RegExp(r'\?(\s|$)').allMatches(content)) {
    // The question starts after the last sentence end before it, which may
    // carry a closing quote or bracket: "… add 5.' What are terms?"
    final before = content.substring(from, m.start);
    final ends = _sentenceEnd.allMatches(before);
    final start = ends.isEmpty ? from : from + ends.last.end;
    questions.add((start, m.start + 1));
    from = m.end;
  }
  if (questions.isEmpty) {
    return ('', [ExplanationSection(heading: 'Explanation', body: content.trim())]);
  }
  final sections = <ExplanationSection>[];
  var pending = '';
  for (var i = 0; i < questions.length; i++) {
    final (start, end) = questions[i];
    final last = i + 1 == questions.length;
    final next = last ? content.length : questions[i + 1].$1;
    final body = content.substring(end, next).trim();
    final heading = content.substring(start, end).trim();
    if (body.isEmpty) {
      if (last && sections.isNotEmpty) {
        // A closing question ("What story does this data tell?") belongs
        // to the answer before it.
        final prev = sections.removeLast();
        sections.add(ExplanationSection(heading: prev.heading, body: '${prev.body} $heading'));
      } else {
        // Two questions in a row: one heading, answered by what follows.
        pending = '$pending$heading ';
      }
      continue;
    }
    sections.add(ExplanationSection(heading: '$pending$heading', body: body));
    pending = '';
  }
  return (content.substring(0, questions.first.$1).trim(), sections);
}

final _sentenceEnd = RegExp('[.!;:][\'"’”)\\]]*\\s+(?=[A-Z])');

/// "Problem\nStep 1: …\nAnswer: …" as a problem, its steps, and the answer.
String _workedExample(String example) {
  final lines = example.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
  return [
    for (final l in lines)
      if (l.startsWith('Answer:'))
        '**Answer:**${l.substring('Answer:'.length)}'
      else if (l.startsWith('Step '))
        '- $l'
      else
        l,
  ].join('\n');
}

const _topicPrefixes = [
  'an introduction to ',
  'introduction to ',
  'first principles of ',
  'principles of ',
  'basics of ',
  'the concept of ',
  'concept of ',
  'the ',
];

/// The names a learner may use for a lesson: its title, without any
/// "(…)" part and without "Introduction to"-style openings ("First Principles
/// of Algebra" → "algebra").
List<String> lessonTopicNames(String title) {
  final names = <String>[];
  void add(String n) {
    final t = normalizeTopicText(n);
    if (t.length >= 4 && !names.contains(t)) names.add(t);
  }

  add(title);
  final plain = title.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
  add(plain);
  // "Algebra 1" is the first lesson called algebra.
  add(plain.replaceFirst(RegExp(r'\s+\d+$'), ''));
  for (final p in _topicPrefixes) {
    if (plain.toLowerCase().startsWith(p)) add(plain.substring(p.length));
  }
  if (names.isEmpty) names.add(title.toLowerCase());
  return names;
}

/// Lower case, punctuation as spaces, single spaces: how topic names and
/// messages are compared.
String normalizeTopicText(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\w\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Set<String> _words(String text) => {
  for (final m in RegExp(r'[a-z0-9]{2,}').allMatches(text.toLowerCase()))
    m[0]!.length > 4 && m[0]!.endsWith('s') && !m[0]!.endsWith('ss') ? m[0]!.substring(0, m[0]!.length - 1) : m[0]!,
};

// A passing mention such as 'know where the first aid kit is' does not
// supply an explanation of first aid.
bool _explainsNamedTopic(String text, String topic) {
  final normalized = normalizeTopicText(text);
  final name = normalizeTopicText(topic);
  final phrase = RegExp('\\b${RegExp.escape(name)}\\b');
  return phrase.allMatches(normalized).length >= 2 ||
      RegExp('(?:^|[.!?]\\s+)${RegExp.escape(name)}\\s+(?:is|are|means|refers)\\b',
              caseSensitive: false)
          .hasMatch(text);
}

/// "What is photosynthesis?", "Explain photosynthesis fully", "Teach me about
/// …": an ask for the whole topic rather than one detail of it.
final _askForTopic = RegExp(
  r'^(please\s+)?(can you\s+|could you\s+)?'
  r'(what\s+(is|are)|who\s+(is|are|was|were)|where\s+(is|are)|explain|describe|define|teach me( about)?|tell me( all)? about|'
  r'help me (to )?understand|i want to (learn|understand)( about)?|what do you know about)\s+',
);

final _filler = RegExp(
  r'\b(fully|in full|in detail|everything|all|about|the topic|topic|of|to me|'
  r'please|again|for me|simply|well|properly|a|an|the|'
  // "Where is Africa located on the global scale?" → "africa".
  r'located|situated|on (the )?(global scale|world map|map)|in the world)\b',
);

/// The topic a "What is …?" / "Explain …" question names, without the ask
/// and filler words ("Explain photosynthesis fully" → "photosynthesis"), or
/// null when [message] isn't such a question.
String? askedTopic(String message) {
  final who = whoTopic(message);
  if (who != null) return who;
  final m = normalizeTopicText(message);
  final ask = _askForTopic.firstMatch(m);
  if (ask == null) return null;
  final rest = m
      .substring(ask.end)
      .replaceAll(_filler, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return rest.isEmpty ? null : rest;
}

final _askWho = RegExp(r'^(please\s+)?(can you tell me\s+|do you know\s+)?who\s+(is|are|was|were)\s+');

/// The person or office a "Who is …?" question names, keeping its small
/// words so it reads as a page name ("Who is the president of Uganda?" →
/// "president of uganda"), or null when [message] isn't one. The on-device
/// model can't know people or current office-holders reliably.
String? whoTopic(String message) {
  final m = normalizeTopicText(message);
  final ask = _askWho.firstMatch(m);
  if (ask == null) return null;
  final rest = m.substring(ask.end).replaceFirst(RegExp(r'^(the|a|an)\s+'), '').trim();
  return rest.isEmpty ? null : rest;
}

final _pictureWords = RegExp(
  r'\b(photos?|photographs?|pictures?|pics?|images?|diagrams?|illustrations?|'
  r'drawings?|look like|looks like)\b',
);

const _pictureFiller = {
  'give', 'me', 'show', 'send', 'can', 'could', 'would', 'you', 'i', 'have',
  'draw', 'sketch', 'illustrate', 'want', 'need', 'see', 'let', 'display', 'a', 'an', 'the', 'some', 'any',
  'more', 'please', 'of', 'it', 'this', 'that', 'them', 'these', 'those', 'do',
  'get', 'us', 'there', 'is', 'are', 'what', 'how', 'does', 'did', 'look',
  'looks', 'like', 'for', 'showing', 'with', 'one', 'another', 'other', 'real',
  'nice', 'good', 'clear', 'and', 'or', 'to', 'its', 'my', 'your', 'also',
  'about', 'on', 'their', 'his', 'her', 'him', 'he', 'she',
  // Talk around a correction: "I mean show me the picture of …".
  'mean', 'meant', 'actually', 'just', 'now', 'instead', 'sorry', 'no', 'ok',
  'okay', 'again', 'only', 'said', 'asked', 'wanted',
};

/// Words that point back to what the chat was about ("pictures of its
/// cultures": "its" is the topic asked about before).
final _backReference = RegExp(r'\b(its|their|it|them|this|that|these|those|his|her|him|he|she|there)\b');

/// The words of an earlier topic that a back-reference most likely means:
/// the place or thing after "in"/"of" first ("population and urbanisation
/// in africa" → africa), then the rest in order.
const _topicGlue = {
  'and', 'in', 'of', 'the', 'a', 'an', 'its', 'their', 'to', 'for', 'on',
  'about', 'with', 'what', 'is', 'are', 'how', 'why',
};

/// The subjects to look up, best first, for a picture request whose subject
/// is [subject] (from [pictureRequestSubject], not empty). When [message]
/// points back ("its diverse cultures") and the chat was about [earlier]
/// ("africa"), the earlier topic joins it: "africa diverse cultures".
List<String> pictureSubjectCandidates(String message, String subject, String? earlier) {
  if (earlier == null || earlier.isEmpty || !_backReference.hasMatch(normalizeTopicText(message))) {
    return [subject];
  }
  final own = subject.split(' ').toSet();
  final words = normalizeTopicText(earlier).split(' ');
  final after = <String>[];
  final rest = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.length < 3 || _topicGlue.contains(w) || own.contains(w)) continue;
    final afterGlue = i > 0 && (words[i - 1] == 'in' || words[i - 1] == 'of');
    final list = afterGlue ? after : rest;
    if (!list.contains(w)) list.add(w);
  }
  return [
    for (final w in [...after, ...rest].take(2)) '$w $subject',
    subject,
  ];
}

/// Whether [message] asks for a picture, and of what: null when it doesn't
/// ask for one; '' for a picture of what the chat is about ("give me a
/// photo"); otherwise the subject ("a photo of a frog" → "frog").
String? pictureRequestSubject(String message) {
  final m = normalizeTopicText(message);
  // "Explain the diagram on page 14" is about a teacher's PDF, not a request.
  if (m.split(' ').length > 14 || RegExp(r'\bpage\b').hasMatch(m)) {
    return null;
  }
  var subject = m;
  if (!_pictureWords.hasMatch(m)) {
    final command = RegExp(
      r'^(please )?((can|could|would) you )?'
      r'(show|draw|sketch|illustrate|display)( me| us| for me)?\s+(.+)$',
    ).firstMatch(m);
    if (command == null) return null;
    subject = command.group(6)!;
    // Keep requests for explanations, solutions and app navigation on their
    // normal paths. A bare visual command names an object, not a workflow.
    if (RegExp(r'\b(how|why|steps|working|solution|solutions|answer|answers|'
        r'proof|code|example|examples|progress|assignments|notes|settings|'
        r'video|videos|clip|clips)\b').hasMatch(subject)) {
      return null;
    }
  }
  final rest = [
    for (final w in subject.replaceAll(_pictureWords, ' ').split(' '))
      if (w.isNotEmpty && !_pictureFiller.contains(w)) w,
  ];
  return rest.join(' ');
}

final _clipWords = RegExp(r'\b(clips?|videos?|footage|films?|animations?|movies?)\b');

/// Like [pictureRequestSubject], for video clips: "show me a video of a
/// volcano" → "volcano"; "any clips?" → '' (the topic under way).
String? clipRequestSubject(String message) {
  final m = normalizeTopicText(message);
  if (!_clipWords.hasMatch(m) || m.split(' ').length > 14 || m.contains('page')) {
    return null;
  }
  final rest = [
    for (final w in m.replaceAll(_clipWords, ' ').replaceAll(_pictureWords, ' ').split(' '))
      if (w.isNotEmpty && !_pictureFiller.contains(w) && w != 'watch' && w != 'play') w,
  ];
  return rest.join(' ');
}

/// Whether [message] asks for the whole of a topic named by one of
/// [aliases] — the ask itself plus nothing more than the topic's name.
bool asksForWholeTopic(String message, List<String> aliases) {
  final rest = askedTopic(message);
  if (rest == null) return false;
  for (final a in aliases) {
    final alias = a.replaceAll(_filler, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rest == alias || rest == '${alias}s' || '${rest}s' == alias) return true;
  }
  return false;
}

/// The topic explanations on this device:
/// - reviewed packs bundled in the app, overridden per topic by any newer
///   pack in `<app support>/otic_topic_packs/` (where a pack update is saved);
/// - every lesson of the bundled curriculum, read as it is
///   ([TopicExplanation.fromLesson]).
///
/// A pack topic wins over a lesson on the same subject matter. Bundled
/// packs and the curriculum are the fallback, so an install that never
/// updates still has every topic.
class TopicExplanationService {
  TopicExplanationService({
    AssetBundle? bundle,
    Future<Directory?> Function()? updatesDir,
    Future<List<Subject>> Function()? subjects,
  }) : _bundle = bundle ?? rootBundle,
       _updatesDir = updatesDir ?? _defaultUpdatesDir,
       _subjects = subjects;

  /// Pack files bundled under `assets/topic_explanations/`.
  static const bundledPacks = ['biology'];

  final AssetBundle _bundle;
  final Future<Directory?> Function() _updatesDir;
  final Future<List<Subject>> Function()? _subjects;
  Future<List<TopicExplanation>>? _loading;
  Future<List<TopicExplanation>>? _lessons;

  /// Every curriculum lesson as an explanation.
  Future<List<TopicExplanation>> lessons() => _lessons ??= _loadLessons();

  Future<List<TopicExplanation>> _loadLessons() async {
    final source = _subjects;
    if (source == null) return const [];
    var added = const <String, LessonDiagram>{};
    try {
      added = LessonDiagram.parseAll(
        await _bundle.loadString('assets/topic_explanations/diagrams.json'),
      );
    } catch (e) {
      debugPrint('Lesson diagrams not loaded: $e');
    }
    try {
      return [
        for (final s in await source())
          for (final u in s.units)
            for (final l in u.lessons)
              TopicExplanation.fromLesson(
                l,
                subjectId: s.id,
                subjectName: s.name,
                unitTitle: u.title,
                addedDiagram: added['${s.id}|${l.title}'],
              ),
      ];
    } catch (e) {
      debugPrint('Curriculum lessons not read as explanations: $e');
      return const [];
    }
  }

  static Future<Directory?> _defaultUpdatesDir() async {
    try {
      final base = await getApplicationSupportDirectory();
      return Directory('${base.path}/otic_topic_packs');
    } catch (_) {
      return null;
    }
  }

  /// Every topic, newest version of each id.
  Future<List<TopicExplanation>> all() => _loading ??= _load();

  Future<List<TopicExplanation>> _load() async {
    final byId = <String, TopicExplanation>{};
    void take(String json) {
      for (final t in parsePack(json)) {
        final had = byId[t.id];
        if (had == null || t.version > had.version) byId[t.id] = t;
      }
    }

    for (final id in bundledPacks) {
      try {
        take(await _bundle.loadString('assets/topic_explanations/$id.json'));
      } catch (e) {
        debugPrint('Topic pack $id not loaded: $e');
      }
    }
    try {
      final dir = await _updatesDir();
      if (dir != null && await dir.exists()) {
        await for (final f in dir.list()) {
          if (f is File && f.path.endsWith('.json')) {
            try {
              take(await f.readAsString());
            } catch (e) {
              debugPrint('Topic pack update ${f.path} skipped: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Topic pack updates not read: $e');
    }
    return byId.values.toList();
  }

  /// Topics in one pack file: `{"subject": "Biology", "topics": [...]}`.
  static List<TopicExplanation> parsePack(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final subject = data['subject'] as String;
    return [
      for (final t in data['topics'] as List)
        TopicExplanation.fromJson(t as Map<String, dynamic>, subjectName: subject),
    ];
  }

  /// The topic [message] is about, or null. A topic matches when one of its
  /// names appears in the message as whole words. A pack topic comes first;
  /// among lessons, a lesson's own title beats a key term, then the longest
  /// name wins.
  Future<TopicExplanation?> match(String message) async {
    final m = ' ${normalizeTopicText(message)} ';
    TopicExplanation? best(List<TopicExplanation> topics) {
      TopicExplanation? found;
      var bestScore = 0;
      for (final t in topics) {
        for (final a in t.aliases) {
          final score = a.length + (t.wholeTopicNames.contains(a) ? 1000 : 0);
          if (score > bestScore && m.contains(' $a ')) {
            found = t;
            bestScore = score;
          }
        }
      }
      return found;
    }

    return best(await all()) ?? best(await lessons());
  }

  /// For a "Teach me about …" whose topic no lesson is named after
  /// ("triangles"), the lesson that covers it most: the topic's words in its
  /// title count most, then in its key terms, then in its text. Null when
  /// nothing covers it well, or [message] asks for no topic. Used to ground
  /// an answer, never shown whole.
  Future<TopicExplanation?> covering(String message) async {
    final topic = askedTopic(message);
    if (topic == null) return null;
    final asked = {
      for (final w in _words(topic))
        if (!_coveringStopWords.contains(w)) w,
    };
    if (asked.isEmpty) return null;
    TopicExplanation? found;
    var bestScore = 0;
    for (final t in [...await all(), ...await lessons()]) {
      final title = _words(t.title);
      final terms = _words(t.keyTerms.keys.join(' '));
      final body = [for (final s in t.sections) '${s.heading} ${s.body}'].join(' ').toLowerCase();
      // A named topic must be present as a phrase, or in the lesson's
      // title/key terms. Separate mentions of 'first' and 'aid' do not
      // make a camera lesson about first aid.
      if (asked.length > 1 &&
          !asked.every({...title, ...terms}.contains) &&
          !_explainsNamedTopic(body, topic)) continue;
      var score = 0;
      for (final w in asked) {
        if (title.contains(w)) score += 10;
        if (terms.contains(w)) score += 5;
        score += RegExp('\\b${RegExp.escape(w)}').allMatches(body).length.clamp(0, 8);
      }
      if (score > bestScore) {
        found = t;
        bestScore = score;
      }
    }
    return bestScore >= 4 ? found : null;
  }

  Future<Map<String, LessonDiagram>>? _topicDiagrams;

  /// Pictures for topics no single lesson is about ("triangle"), from
  /// `assets/topic_explanations/topic_diagrams.json`, keyed by word.
  Future<Map<String, LessonDiagram>> _diagramsByTopic() => _topicDiagrams ??= () async {
    try {
      return LessonDiagram.parseAll(
        await _bundle.loadString('assets/topic_explanations/topic_diagrams.json'),
      );
    } catch (e) {
      debugPrint('Topic diagrams not loaded: $e');
      return const <String, LessonDiagram>{};
    }
  }();

  /// A full explanation of a topic that no lesson is named after ("Teach me
  /// about triangles"), put together from every lesson that teaches it: the
  /// parts of each lesson about it, worked examples, key terms and practice
  /// questions, with a picture when there is one. Null when [message] asks
  /// for no topic or the curriculum says too little about it.
  Future<TopicExplanation?> compose(String message) async {
    final topic = askedTopic(message);
    if (topic == null) return null;
    final asked = {
      for (final w in _words(topic))
        if (!_coveringStopWords.contains(w)) w,
    };
    if (asked.isEmpty) return null;
    bool about(String text) {
      final words = _words(text);
      return asked.every(words.contains) &&
          (asked.length == 1 ||
              _explainsNamedTopic(text, topic));
    }

    final parts = <({TopicExplanation lesson, ExplanationSection section, int hits})>[];
    for (final t in await lessons()) {
      for (final s in t.sections) {
        if (s.heading.startsWith('Worked example')) continue;
        final text = '${s.heading} ${s.body}';
        if (!about(text)) continue;
        final hits = [
          for (final w in asked) RegExp('\\b${RegExp.escape(w)}').allMatches(text.toLowerCase()).length,
        ].fold(0, (a, b) => a + b);
        parts.add((lesson: t, section: s, hits: hits));
      }
    }
    if (parts.length < 2) return null;
    parts.sort((a, b) => b.hits.compareTo(a.hits));
    // The most relevant parts, then taught in class order: S1 basics first.
    final chosen = parts.take(6).toList()
      ..sort((a, b) => a.lesson.level.compareTo(b.lesson.level));
    final lessonsUsed = <TopicExplanation>{for (final p in chosen) p.lesson}.toList();

    final examples = [
      for (final t in lessonsUsed)
        for (final s in t.sections)
          if (s.heading.startsWith('Worked example') && about(s.body)) (t, s),
    ].take(3).toList();
    final terms = <String, String>{
      for (final t in lessonsUsed)
        for (final e in t.keyTerms.entries)
          if (about('${e.key} ${e.value}')) e.key: e.value,
    };
    final practice = [
      for (final t in lessonsUsed)
        for (final q in t.checkQuestions)
          if (about(q)) q,
    ].take(4).toList();

    final pictures = await _diagramsByTopic();
    LessonDiagram? picture;
    for (final w in asked) {
      picture ??= pictures[w];
    }
    final diagram = picture?.asset ??
        [for (final t in lessonsUsed) t.diagram].whereType<String>().firstOrNull;

    final name = topic[0].toUpperCase() + topic.substring(1);
    // The subjects that teach it most ("Agriculture, Geography"), not just
    // whichever lesson came first.
    final weight = <String, int>{};
    for (final p in chosen) {
      weight[p.lesson.subjectName] = (weight[p.lesson.subjectName] ?? 0) + p.hits;
    }
    final subject = (weight.keys.toList()..sort((a, b) => weight[b]!.compareTo(weight[a]!)))
        .take(2)
        .join(', ');
    return TopicExplanation(
      id: 'compose.${normalizeTopicText(topic).replaceAll(' ', '_')}',
      subjectName: subject,
      level: ({for (final t in lessonsUsed) t.level}.toList()..sort()).join(', '),
      title: name,
      version: 0,
      aliases: [normalizeTopicText(topic)],
      summary: 'Where this is taught: '
          '${lessonsUsed.map((t) => '${t.title} (${t.level})').join('; ')}. '
          'Here is what ${lessonsUsed.length == 1 ? 'that lesson' : 'each lesson'} '
          'teaches about it.',
      sections: [
        for (final p in chosen)
          ExplanationSection(
            heading: '${p.section.heading} — ${p.lesson.title}, ${p.lesson.level}',
            body: p.section.body,
          ),
        for (final (t, s) in examples)
          ExplanationSection(heading: '${s.heading} — ${t.title}', body: s.body),
        if (terms.isNotEmpty)
          ExplanationSection(
            heading: 'Key terms',
            body: [for (final e in terms.entries) '- **${e.key}**: ${e.value}'].join('\n'),
          ),
      ],
      keyTerms: terms,
      diagram: diagram,
      checkQuestions: practice,
    );
  }

  /// The bundled picture for [subject], and the lesson or topic it belongs
  /// to: a topic picture ("triangle"), a lesson or pack named after it, or
  /// one the lessons teaching it carry. Null when the device has none.
  Future<TopicExplanation?> localPicture(String subject) async {
    final pictures = await _diagramsByTopic();
    for (final w in _words(subject)) {
      final p = pictures[w];
      if (p != null) {
        final about = await match(subject) ?? await compose('teach me about $subject');
        return TopicExplanation(
          id: 'picture.$w',
          subjectName: about?.subjectName ?? '',
          level: about?.level ?? '',
          title: about?.title ?? subject,
          version: 0,
          aliases: [w],
          summary: '',
          sections: const [],
          diagram: p.asset,
        );
      }
    }
    for (final t in [await match(subject), await compose('teach me about $subject')]) {
      if (t?.diagram != null) return t;
    }
    return null;
  }

  static const _coveringStopWords = {
    'what', 'about', 'some', 'more', 'with', 'from', 'that', 'this', 'there',
    'their', 'they', 'have', 'does', 'work', 'works', 'mean', 'means', 'thing',
  };
}

final topicExplanationServiceProvider = Provider<TopicExplanationService>(
  (ref) => TopicExplanationService(
    subjects: () => ref.read(curriculumServiceProvider).loadAll(),
  ),
);
