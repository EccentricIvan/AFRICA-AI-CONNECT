import 'package:drift/drift.dart';
import 'students_table.dart';

/// Compressed AI-generated summary after each learning session.
/// Never stores full conversation logs — only the extracted insight.
class SessionSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get topic => text()();
  // 2-3 sentence AI-compressed summary of what was covered
  TextColumn get summary => text()();
  // JSON arrays — ["understood photosynthesis stages"]
  TextColumn get strengthsJson => text().withDefault(const Constant('[]'))();
  TextColumn get weaknessesJson => text().withDefault(const Constant('[]'))();
  // Which pipeline stage they reached in this session
  TextColumn get highestStage =>
      text().withDefault(const Constant('answer'))();
  IntColumn get messageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get sessionAt =>
      dateTime().withDefault(currentDateAndTime)();
}
