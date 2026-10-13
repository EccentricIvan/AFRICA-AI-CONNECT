import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/otic_database.dart';
import '../../db/providers/db_provider.dart';

/// When the tutor last replied to the active learner, in memory only: set
/// while a chat reply streams and when it lands, and when Practice gives
/// feedback on a scenario.
///
/// A quiz answer given after the tutor replied (and after the question
/// appeared) is marked "Tutor used". That records that the two happened
/// together on this device, not that the tutor gave the answer, and it says
/// nothing about help from outside the app. Cleared on every learner switch,
/// so one learner's chat never marks the next learner's answers.
final tutorLastReplyProvider = StateProvider<DateTime?>((ref) => null);

/// Whether the tutor replied after [since].
bool tutorUsedSince(DateTime? lastReply, DateTime since) =>
    lastReply != null && lastReply.isAfter(since);

/// The tutor replied to the active learner: marks it in memory (quizzes)
/// and on disk (assignments, which can span days and app restarts). Called
/// once per reply, never per streamed token.
Future<void> recordTutorReply(Ref ref) async {
  final at = DateTime.now();
  ref.read(tutorLastReplyProvider.notifier).state = at;
  try {
    final student = await ref.read(activeStudentProvider.future);
    if (student == null) return;
    await persistTutorReply(ref.read(dbProvider), student.id, at);
  } catch (_) {
    // Best-effort: a missed mark never fails the reply.
  }
}

/// Stores that the tutor replied to [studentId] at [at] on each assignment
/// they have open (a timed attempt running, or an untimed one seen and not
/// yet answered) that has no reply yet. A time only, never what was said.
Future<void> persistTutorReply(OticDatabase db, int studentId, DateTime at) =>
    (db.update(db.assignmentAttempts)
          ..where((t) => t.studentId.equals(studentId))
          ..where((t) => t.tutorAt.isNull()))
        .write(
          AssignmentAttemptsCompanion(
            tutorAt: Value(at.toUtc().toIso8601String()),
          ),
        );
