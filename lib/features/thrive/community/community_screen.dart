import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
              icon: const Icon(Icons.group_add), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommunityHero(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Your Groups',
                  subtitle: 'Communities you belong to',
                ),
                const SizedBox(height: 12),
                _EmptyGroupsState(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Discover Groups',
                  subtitle: 'Join women\'s groups in your area',
                ),
                const SizedBox(height: 12),
                _DiscoverGroups(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Community Feed',
                  subtitle: 'Latest from women in your network',
                ),
                const SizedBox(height: 12),
                _CommunityFeed(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.communityColor.withValues(alpha: 0.12),
            AppColors.thriveColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.communityColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stronger together',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect with women\'s groups, share experiences, support each other, and grow together.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.communityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.people,
                color: AppColors.communityColor, size: 28),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.groups,
              size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Join a group below or create your own',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create a Group'),
          ),
        ],
      ),
    );
  }
}

class _DiscoverGroups extends StatelessWidget {
  static const _groups = [
    _Group('Kampala Women Entrepreneurs', '124 members',
        Icons.trending_up, AppColors.earnColor),
    _Group('Digital Skills Network', '89 members',
        Icons.computer, AppColors.skillsColor),
    _Group('Farmers United', '256 members',
        Icons.agriculture, AppColors.healthColor),
    _Group('Young Mothers Support', '67 members',
        Icons.child_care, AppColors.thriveColor),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _groups.map((g) {
        return Card(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: g.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(g.icon, color: g.color, size: 22),
            ),
            title: Text(g.name,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(g.members),
            trailing: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Join', style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Group {
  const _Group(this.name, this.members, this.icon, this.color);
  final String name;
  final String members;
  final IconData icon;
  final Color color;
}

class _CommunityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final posts = [
      const _Post('Sarah M.', 'Just completed the Digital Skills course! So proud of this journey.',
          '2 hours ago', AppColors.skillsColor),
      const _Post('Grace K.', 'My basket-weaving business got its first wholesale order today!',
          '5 hours ago', AppColors.earnColor),
      const _Post('Peace N.', 'Looking for women interested in forming a SACCO in Gulu district.',
          '1 day ago', AppColors.financeColor),
    ];

    return Column(
      children: posts.map((p) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: p.color.withValues(alpha: 0.12),
                      child: Text(
                        p.author[0],
                        style: TextStyle(
                          color: p.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.author,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(p.time,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).hintColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(p.content,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _FeedAction(Icons.favorite_border, 'Like'),
                    SizedBox(width: 16),
                    _FeedAction(Icons.chat_bubble_outline, 'Comment'),
                    SizedBox(width: 16),
                    _FeedAction(Icons.share_outlined, 'Share'),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Post {
  const _Post(this.author, this.content, this.time, this.color);
  final String author;
  final String content;
  final String time;
  final Color color;
}

class _FeedAction extends StatelessWidget {
  const _FeedAction(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
