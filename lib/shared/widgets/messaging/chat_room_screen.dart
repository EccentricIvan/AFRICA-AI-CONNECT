import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../db/database.dart';
import '../../../db/providers/database_provider.dart';
import '../../../features/thrive/community/community_screen.dart';

/// Generic persisted chat thread — used by Mentorship "Connect", Marketplace
/// "Chat with seller", and Community group chat. Reads/writes through
/// MessagingDao's Conversations/Messages tables instead of an in-memory
/// list, so history survives navigating away and app restarts.
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId});
  final int conversationId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final user = await ref.read(currentUserProvider.future);
    await ref.read(messagingDaoProvider).sendMessage(
          conversationId: widget.conversationId,
          senderIsMe: true,
          senderName: user?.name ?? S.literal('Me'),
          body: text,
        );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(conversationProvider(widget.conversationId));
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));

    final conversation = conversationAsync.valueOrNull;
    final title = Text(conversation?.title ?? S.literal('Chat'));

    // A 'group' conversation's subjectId is the group id directly; a
    // 'mentor' conversation's subjectId is a mentor id, resolved back to
    // that mentor's circle — same lookup _GroupLinkTitle uses below.
    int? groupId;
    if (conversation?.type == 'group') {
      groupId = conversation!.subjectId;
    } else if (conversation?.type == 'mentor') {
      groupId = ref.watch(groupForMentorProvider(conversation!.subjectId)).valueOrNull?.id;
    }
    final isClosed = groupId != null &&
        ref.watch(groupProvider(groupId)).valueOrNull?.closedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: conversation == null || conversation.type == 'marketplace'
            ? title
            : _GroupLinkTitle(conversation: conversation, title: title),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(S.literal('Could not load messages.'))),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      S.literal('Say hello to start the conversation.'),
                      style: TextStyle(color: AppColors.of(context).textHint),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    return Align(
                      alignment: m.senderIsMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: m.senderIsMe
                              ? AppColors.primary
                              : AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(16),
                          border: m.senderIsMe
                              ? null
                              : Border.all(color: AppColors.of(context).border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!m.senderIsMe)
                              Text(
                                m.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.of(context).textHint,
                                ),
                              ),
                            Text(
                              m.body,
                              style: TextStyle(
                                color: m.senderIsMe ? Colors.white : AppColors.of(context).textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: isClosed
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.of(context).textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            S.literal('This community was closed by its creator. You can no longer send messages here.'),
                            style: TextStyle(fontSize: 13, color: AppColors.of(context).textHint),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: S.literal('Type a message…'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Makes the AppBar title tappable for group/mentor threads — resolves a
/// 'mentor' conversation's subjectId (a mentor id) back to that mentor's
/// circle before navigating, since a 'group' conversation's subjectId is
/// already the group id directly.
class _GroupLinkTitle extends ConsumerWidget {
  const _GroupLinkTitle({required this.conversation, required this.title});
  final Conversation conversation;
  final Widget title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupIdAsync = conversation.type == 'group'
        ? AsyncData<int?>(conversation.subjectId)
        : ref.watch(groupForMentorProvider(conversation.subjectId)).whenData((g) => g?.id);
    final groupId = groupIdAsync.valueOrNull;

    return InkWell(
      onTap: groupId == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GroupDetailPage(groupId: groupId)),
              ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: title),
          if (groupId != null) const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}
