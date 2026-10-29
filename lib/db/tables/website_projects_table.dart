import 'package:drift/drift.dart';
import 'students_table.dart';

class WebsiteProjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  // '#rrggbb' page accent color
  TextColumn get themeColor => text().withDefault(const Constant('#4F46E5'))();
  // JSON array of SiteBlock objects (see features/website/block_models.dart)
  TextColumn get blocksJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
