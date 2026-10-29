import 'package:drift/drift.dart';
import 'students_table.dart';

class EarnedBadges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get badgeId => text()();
  TextColumn get badgeName => text()();
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {studentId, badgeId}
      ];
}
