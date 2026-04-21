import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/story_service.dart';
import '../../models/user_model.dart';
import '../../models/story_model.dart';
import '../../widgets/user_avatar.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    return SizedBox(
      height: 96,
      child: StreamBuilder<List<UserStoriesGroup>>(
        stream: StoryService().getFeedStories(user.id, user.contacts),
        builder: (ctx, snap) {
          final groups = snap.data ?? [];
          final hasOwnStories = groups.any((g) => g.userId == user.id);
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length + (hasOwnStories ? 0 : 1),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              if (!hasOwnStories && i == 0) {
                return _MyStoryItem(user: user);
              }
              final gi = hasOwnStories ? i : i - 1;
              if (gi >= groups.length) return const SizedBox();
              final group = groups[gi];
              final isOwn = group.userId == user.id;
              return _StoryItem(group: group, viewerId: user.id, isOwn: isOwn, onTap: () {
                if (group.activeStories.isEmpty) return;
                Navigator.pushNamed(context, AppRoutes.storyView, arguments: {
                  'stories': group.activeStories,
                  'initialIndex': 0,
                });
              });
            },
          );
        },
      ),
    );
  }
}

class _MyStoryItem extends StatelessWidget {
  final UserModel user;
  const _MyStoryItem({required this.user});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, AppRoutes.addStory),
    child: Column(children: [
      Stack(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.divider, width: 2)),
          child: ClipOval(child: UserAvatar(photoUrl: user.photoUrl, name: user.name, size: 56)),
        ),
        Positioned(bottom: 0, right: 0, child: Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
          child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
        )),
      ]),
      const SizedBox(height: 4),
      SizedBox(width: 64, child: Text(AppLocalizations.of(context)['addStory'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)))),
    ]),
  );
}

class _StoryItem extends StatelessWidget {
  final UserStoriesGroup group;
  final String viewerId;
  final bool isOwn;
  final VoidCallback onTap;
  const _StoryItem({required this.group, required this.viewerId, required this.isOwn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unseen = group.hasUnseenStories(viewerId);
    final count = group.activeStories.length;
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        _StoryRing(photoUrl: group.userPhotoUrl, name: group.userName, size: 60, count: count, unseen: unseen),
        const SizedBox(height: 4),
        SizedBox(width: 64, child: Text(isOwn ? AppLocalizations.of(context)['myStory'] : group.userName,
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: isOwn ? FontWeight.w700 : FontWeight.w400))),
      ]),
    );
  }
}

class _StoryRing extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final int count;
  final bool unseen;
  const _StoryRing({this.photoUrl, required this.name, required this.size, required this.count, required this.unseen});
  @override
  Widget build(BuildContext context) {
    final ringColor = unseen ? AppColors.storyUnseen : AppColors.storySeen;
    return Container(
      width: size + 6, height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unseen ? LinearGradient(colors: [AppColors.storyGradientStart, AppColors.storyGradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: unseen ? null : AppColors.storySeen,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.bgDark, width: 2)),
          child: ClipOval(child: UserAvatar(photoUrl: photoUrl, name: name, size: size)),
        ),
      ),
    );
  }
}