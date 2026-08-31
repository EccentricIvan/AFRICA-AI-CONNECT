import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/groups_table.dart';

part 'groups_dao.g.dart';

@DriftAccessor(tables: [Groups, GroupMembers])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  /// Browsable/joinable communities — a closed one drops out of Discover,
  /// though it stays visible to its existing members via watchMyGroups.
  Stream<List<Group>> watchGroups() {
    return (select(groups)
          ..where((g) => g.closedAt.isNull())
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  /// Groups the local user has joined — a real SQL join against
  /// GroupMembers rather than filtering in Dart. Includes closed groups so
  /// a member can still see one was closed and why they can't post.
  Stream<List<Group>> watchMyGroups() {
    final query = select(groups).join([
      innerJoin(
        groupMembers,
        groupMembers.groupId.equalsExp(groups.id) &
            groupMembers.isMe.equals(true),
      ),
    ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(groups)).toList(),
    );
  }

  Stream<Group?> watchGroup(int id) =>
      (select(groups)..where((g) => g.id.equals(id))).watchSingleOrNull();

  /// The circle auto-created for a given mentor, if one exists yet — used
  /// to resolve a 'mentor'-type conversation's subjectId (a mentor id, not
  /// a group id) back to its group for the "view details" link.
  Stream<Group?> watchGroupForMentor(int mentorId) =>
      (select(groups)..where((g) => g.mentorId.equals(mentorId)))
          .watchSingleOrNull();

  Stream<List<GroupMember>> watchMembers(int groupId) {
    return (select(
      groupMembers,
    )..where((m) => m.groupId.equals(groupId))).watch();
  }

  /// Reactive — true once the local user has joined this group.
  Stream<bool> watchIsMember(int groupId) {
    return (select(groupMembers)
          ..where((m) => m.groupId.equals(groupId) & m.isMe.equals(true)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  Future<int> createGroup({
    required String name,
    required String category,
    required String iconKey,
    required String colorKey,
    String? location,
    String? imagePath,
    String? description,
  }) {
    return into(groups).insert(
      GroupsCompanion.insert(
        name: name,
        category: category,
        iconKey: iconKey,
        colorKey: colorKey,
        location: Value(location),
        imagePath: Value(imagePath),
        description: Value(description),
      ),
    );
  }

  Future<bool> hasAnyGroups() async =>
      (await (select(groups)..limit(1)).get()).isNotEmpty;

  /// Idempotent — reuses a mentor's existing circle instead of creating a
  /// duplicate every time someone connects with that mentor. Falls back to
  /// an auto-named circle only if one doesn't already exist — in normal
  /// use createMentorGroup already created it, with the real name the
  /// mentor chose, at "Become a Mentor" time.
  Future<int> getOrCreateMentorGroup({
    required int mentorId,
    required String mentorName,
    required String colorKey,
  }) async {
    final existing = await (select(groups)
          ..where((g) => g.mentorId.equals(mentorId))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return into(groups).insert(
      GroupsCompanion.insert(
        name: "$mentorName's Circle",
        category: 'mentorship',
        iconKey: 'diversity',
        colorKey: colorKey,
        mentorId: Value(mentorId),
      ),
    );
  }

  /// Creates a mentor's circle with the real name/description they chose
  /// on the "Become a Mentor" form — called once, right after
  /// MentorsDao.createMentor succeeds.
  Future<int> createMentorGroup({
    required int mentorId,
    required String name,
    required String colorKey,
    String? description,
  }) {
    return into(groups).insert(
      GroupsCompanion.insert(
        name: name,
        category: 'mentorship',
        iconKey: 'diversity',
        colorKey: colorKey,
        mentorId: Value(mentorId),
        description: Value(description),
      ),
    );
  }

  Future<void> joinGroup({
    required int groupId,
    required String memberName,
  }) async {
    final existing = await (select(groupMembers)
          ..where((m) => m.groupId.equals(groupId) & m.isMe.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return;
    await into(groupMembers).insert(
      GroupMembersCompanion.insert(
        groupId: groupId,
        memberName: memberName,
        isMe: const Value(true),
      ),
    );
  }

  Future<void> leaveGroup(int groupId) async {
    await (delete(groupMembers)
          ..where((m) => m.groupId.equals(groupId) & m.isMe.equals(true)))
        .go();
  }

  /// The local user's own membership row wherever it exists (no
  /// cross-device sync yet — see CLAUDE.md), kept in step with a profile
  /// name change.
  Future<void> renameMyMembership(String newName) {
    return (update(groupMembers)..where((m) => m.isMe.equals(true)))
        .write(GroupMembersCompanion(memberName: Value(newName)));
  }

  /// Every group on this device was created by the local user themselves
  /// (directly, or auto-created via "Become a Mentor") — so no ownership
  /// check is needed (see CLAUDE.md: no cross-device sync yet). A soft
  /// close rather than a hard delete: the group, its membership, and its
  /// chat history all stay, so members still see it — just marked closed,
  /// no longer postable (see ChatRoomScreen's closed-state gate) and no
  /// longer discoverable (see watchGroups).
  Future<void> closeGroup(int id) {
    return (update(groups)..where((g) => g.id.equals(id)))
        .write(GroupsCompanion(closedAt: Value(DateTime.now())));
  }
}
