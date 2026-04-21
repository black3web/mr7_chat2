import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';
import '../../models/group_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    return Stack(children: [
      StreamBuilder<List<GroupModel>>(
        stream: GroupService().getUserGroups(user.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.group_outlined, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(l['noGroups'], style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 4),
            itemCount: groups.length,
            itemBuilder: (ctx, i) => _GroupTile(group: groups[i], currentUserId: user.id),
          );
        },
      ),
      Positioned(
        bottom: 16, right: 16,
        child: FloatingActionButton(
          heroTag: 'group_fab',
          backgroundColor: AppColors.primary,
          onPressed: () => _showCreateGroupDialog(context, l),
          child: const Icon(Icons.group_add_rounded, color: Colors.white),
        ),
      ),
    ]);
  }

  void _showCreateGroupDialog(BuildContext context, AppLocalizations l) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
      title: Text(l['createGroup'], style: const TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: l['groupName'], prefixIcon: const Icon(Icons.group_rounded, size: 20))),
        const SizedBox(height: 12),
        TextField(controller: usernameCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: l['groupUsername'], prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l['cancel'])),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.isEmpty || usernameCtrl.text.isEmpty) return;
            Navigator.pop(ctx);
            final userId = context.read<AppProvider>().currentUser!.id;
            try {
              final group = await GroupService().createGroup(name: nameCtrl.text.trim(), username: usernameCtrl.text.trim(), creatorId: userId);
              Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'groupId': group.id});
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: Text(l['createGroup']),
        ),
      ],
    ));
  }
}

class _GroupTile extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  const _GroupTile({required this.group, required this.currentUserId});
  @override
  Widget build(BuildContext context) {
    final unread = group.unreadCounts[currentUserId] ?? 0;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'groupId': group.id}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          UserAvatar(photoUrl: group.photoUrl, name: group.name, size: 52),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('${group.members.length}', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 4),
              Icon(Icons.people_rounded, size: 13, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Expanded(child: Text(group.lastMessageText ?? group.description ?? '', style: TextStyle(fontSize: 13, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (unread > 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(10)),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}