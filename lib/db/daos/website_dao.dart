import 'package:drift/drift.dart';
import '../otic_database.dart';
import '../tables/website_projects_table.dart';

part 'website_dao.g.dart';

@DriftAccessor(tables: [WebsiteProjects])
class WebsiteDao extends DatabaseAccessor<OticDatabase>
    with _$WebsiteDaoMixin {
  WebsiteDao(super.db);

  Future<List<WebsiteProject>> getWebsitesForStudent(int studentId) =>
      (select(websiteProjects)
            ..where((t) => t.studentId.equals(studentId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<WebsiteProject?> getWebsiteById(int id) =>
      (select(websiteProjects)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> saveWebsite(WebsiteProjectsCompanion site) =>
      into(websiteProjects).insert(site);

  Future<void> updateWebsite(int id, WebsiteProjectsCompanion data) =>
      (update(websiteProjects)..where((t) => t.id.equals(id))).write(data);

  Future<void> deleteWebsite(int id) =>
      (delete(websiteProjects)..where((t) => t.id.equals(id))).go();
}
