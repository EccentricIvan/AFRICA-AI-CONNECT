import 'package:drift/drift.dart';
import 'students_table.dart';

class StudentProjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId =>
      integer().references(Students, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get topic => text()();
  // 'essay' | 'business_plan' | 'experiment' | 'story' | 'code_plan' | 'other'
  TextColumn get projectType => text()();
  // JSON array of {role:'user'|'otic', text:String} turns saved at project close
  TextColumn get stepsJson => text().withDefault(const Constant('[]'))();
  // 'in_progress' | 'complete'
  TextColumn get status => text().withDefault(const Constant('in_progress'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
