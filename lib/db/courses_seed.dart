import 'daos/courses_dao.dart';

class _TopicSeed {
  const _TopicSeed(this.title, this.questions);
  final String title;
  final List<_QuestionSeed> questions;
}

class _QuestionSeed {
  const _QuestionSeed(this.question, this.options, this.correctIndex);
  final String question;
  final List<String> options;
  final int correctIndex;
}

class _CourseSeed {
  const _CourseSeed(this.title, this.subtitle, this.iconKey, this.colorKey, this.topics);
  final String title;
  final String subtitle;
  final String iconKey;
  final String colorKey;
  final List<_TopicSeed> topics;
}

const _courses = [
  _CourseSeed(
    'Digital Skills',
    'Phone, internet, and mobile money basics',
    'laptop_mac',
    'skills',
    [
      _TopicSeed('Using a Smartphone Safely', [
        _QuestionSeed(
          'What should you do before connecting to public WiFi?',
          ['Nothing special', 'Turn off automatic file sharing and avoid entering passwords', 'Turn off your phone entirely', 'Delete all your apps'],
          1,
        ),
        _QuestionSeed(
          'Which of these is the strongest type of password?',
          ['Your birthday', '123456', 'A mix of letters, numbers, and symbols', 'Your name'],
          2,
        ),
      ]),
      _TopicSeed('Mobile Money Basics', [
        _QuestionSeed(
          'What should you always do after a mobile money transaction?',
          ['Ignore the confirmation SMS', 'Check the confirmation SMS matches what you intended', 'Delete the SMS immediately', 'Share your PIN with the agent'],
          1,
        ),
        _QuestionSeed(
          'Who should you share your mobile money PIN with?',
          ['No one, not even agents or family', 'Your mobile money agent', 'A trusted friend', 'Anyone who asks'],
          0,
        ),
      ]),
    ],
  ),
  _CourseSeed(
    'Financial Literacy',
    'Budgeting, saving, and growing your money',
    'account_balance',
    'finance',
    [
      _TopicSeed('Building a Simple Budget', [
        _QuestionSeed(
          'What is the first step in creating a budget?',
          ['Buy everything you want first', 'List your income and expenses', 'Ignore small expenses', 'Borrow money'],
          1,
        ),
        _QuestionSeed(
          'Why is it useful to track small daily expenses?',
          ["They don't matter", 'They can add up to a large amount over time', "They're illegal", 'They only matter for rich people'],
          1,
        ),
      ]),
      _TopicSeed('Growing Your Savings', [
        _QuestionSeed(
          'What is a benefit of joining a savings group (SACCO)?',
          ['Access to loans and shared savings discipline', "It guarantees you'll never lose money", 'It replaces the need to budget', "It's only for men"],
          0,
        ),
        _QuestionSeed(
          'Which is a good savings habit?',
          ['Saving whatever is left at the end of the month', 'Setting aside a fixed amount first, before spending', 'Never saving', 'Only saving once a year'],
          1,
        ),
      ]),
    ],
  ),
  _CourseSeed(
    'Entrepreneurship',
    'Starting and growing a small business',
    'rocket_launch',
    'earn',
    [
      _TopicSeed('Starting a Small Business', [
        _QuestionSeed(
          'What should you research before starting a business?',
          ['Nothing, just start', "Whether there's demand for your product or service", "Only the price of your rent", "Your competitors' personal lives"],
          1,
        ),
        _QuestionSeed(
          "What is 'value addition' in business?",
          ['Selling raw goods unprocessed', 'Processing or improving a product to sell it for more', 'Lowering your prices below cost', 'Copying a competitor exactly'],
          1,
        ),
      ]),
      _TopicSeed('Pricing Your Products', [
        _QuestionSeed(
          'What should your price cover, at minimum?',
          ['Nothing in particular', 'Your costs plus a profit margin', "Only your competitor's price", 'Whatever feels right that day'],
          1,
        ),
        _QuestionSeed(
          'Why keep records of your sales and costs?',
          ["It's required by law only", 'To know if your business is actually making a profit', "Records aren't useful for small businesses", 'Only for tax evasion'],
          1,
        ),
      ]),
    ],
  ),
  _CourseSeed(
    'Agriculture',
    'Modern farming and post-harvest techniques',
    'agriculture',
    'agriculture',
    [
      _TopicSeed('Improving Crop Yields', [
        _QuestionSeed(
          'Why is crop rotation useful?',
          ['It has no real effect', 'It helps maintain soil fertility and reduce pests', 'It makes farming more expensive', "It's only for large farms"],
          1,
        ),
        _QuestionSeed(
          "What's a benefit of using quality seeds?",
          ['Higher and more reliable yields', 'They cost more so are never worth it', 'No difference from any seed', 'They require no water'],
          0,
        ),
      ]),
      _TopicSeed('Post-Harvest Handling', [
        _QuestionSeed(
          'Why is proper drying and storage of crops important?',
          ['It reduces spoilage and loss after harvest', 'It has no effect on crop quality', "It's only necessary for export crops", 'It makes crops heavier to sell'],
          0,
        ),
        _QuestionSeed(
          'What can happen if produce is stored in damp conditions?',
          ['It stays fresh longer', 'Mould and spoilage are more likely', 'It becomes more valuable', 'Nothing changes'],
          1,
        ),
      ]),
    ],
  ),
  _CourseSeed(
    'Health & Nutrition',
    'Family health and wellbeing essentials',
    'favorite',
    'health',
    [
      _TopicSeed('Balanced Family Meals', [
        _QuestionSeed(
          'What does a balanced meal typically include?',
          ['Only one type of food', 'A mix of carbohydrates, proteins, and vegetables or fruits', 'Only sugar and fats', 'Only meat'],
          1,
        ),
        _QuestionSeed(
          'Why is clean drinking water important for health?',
          ['It has no health impact', 'It helps prevent waterborne diseases', "It's only important for adults", 'Only bottled water matters'],
          1,
        ),
      ]),
      _TopicSeed('Maternal & Child Health Basics', [
        _QuestionSeed(
          'Why are regular antenatal check-ups important during pregnancy?',
          ['They help catch and manage health risks early', 'They are not necessary if you feel fine', 'They are only for first pregnancies', 'They replace the need for a balanced diet'],
          0,
        ),
        _QuestionSeed(
          'Why are childhood immunizations important?',
          ['They protect children from serious preventable diseases', 'They are optional and rarely useful', 'They are only needed once in a lifetime', 'They are only for children in cities'],
          0,
        ),
      ]),
    ],
  ),
  _CourseSeed(
    'Leadership',
    'Community leadership and advocacy skills',
    'emoji_events',
    'community',
    [
      _TopicSeed('Leading with Confidence', [
        _QuestionSeed(
          'What is an important quality of an effective community leader?',
          ['Refusing to listen to others', 'Listening to and involving the people you lead', 'Making all decisions in secret', 'Avoiding responsibility'],
          1,
        ),
        _QuestionSeed(
          'Why is clear communication important in leadership?',
          ['It helps others understand goals and expectations', "It doesn't matter as long as decisions are made", "It's only useful in large organizations", 'It slows things down unnecessarily'],
          0,
        ),
      ]),
      _TopicSeed('Public Speaking & Advocacy', [
        _QuestionSeed(
          'What helps most when preparing to speak in front of a group?',
          ['Improvising with no preparation', 'Knowing your topic well and practicing beforehand', 'Speaking as fast as possible', 'Avoiding eye contact entirely'],
          1,
        ),
        _QuestionSeed(
          "What is 'advocacy' in a community context?",
          ['Ignoring community issues', 'Speaking up and taking action for a cause or group of people', 'Only criticizing others', 'Something only politicians do'],
          1,
        ),
      ]),
    ],
  ),
];

/// One-time seed of the curated skills catalog — categories, topics, and
/// their quiz questions, backing the merged Skills screen (formerly split
/// across Learn Hub and a separate Skills page).
Future<void> seedCoursesIfEmpty(CoursesDao dao) async {
  if (await dao.hasAnyCourses()) return;
  for (final course in _courses) {
    final courseId = await dao.seedCourse(
      title: course.title,
      subtitle: course.subtitle,
      iconKey: course.iconKey,
      colorKey: course.colorKey,
      lessonCount: course.topics.length,
    );
    for (var t = 0; t < course.topics.length; t++) {
      final topic = course.topics[t];
      final topicId = await dao.seedTopic(
        courseId: courseId,
        title: topic.title,
        orderIndex: t,
      );
      for (var q = 0; q < topic.questions.length; q++) {
        final question = topic.questions[q];
        await dao.seedQuestion(
          topicId: topicId,
          question: question.question,
          options: question.options,
          correctIndex: question.correctIndex,
          orderIndex: q,
        );
      }
    }
  }
}
