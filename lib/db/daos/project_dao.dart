import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/student_projects_table.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [StudentProjects])
class ProjectDao extends DatabaseAccessor<OticDatabase>
    with _$ProjectDaoMixin {
  ProjectDao(super.db);

  Future<List<StudentProject>> getProjectsForStudent(int studentId) =>
      (select(studentProjects)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<int> saveProject(StudentProjectsCompanion project) =>
      into(studentProjects).insert(project);

  Future<void> updateProject(int id, StudentProjectsCompanion data) =>
      (update(studentProjects)..where((t) => t.id.equals(id))).write(data);

  Future<void> deleteProject(int id) =>
      (delete(studentProjects)..where((t) => t.id.equals(id))).go();

  Future<int> countProjects(int studentId) async {
    final rows = await getProjectsForStudent(studentId);
    return rows.length;
  }
}
