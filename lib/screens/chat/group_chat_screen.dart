import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import '../../models/group_model.dart';
import '../../widgets/user_avatar.dart';
import 'message_bubble.dart';
import 'group_input_bar.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  MessageModel? _replyingTo;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final me = p.currentUser!;
    final l = AppLocalizations.of(context);
    return StreamBuilder<GroupModel>(
      stream: GroupService().listenToGroup(widget.groupId),
      builder: (ctx, groupSnap) {
        final group = groupSnap.data;
        if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(gradient: AppGradients.backgroundGradient),
            child: SafeArea(
              child: Column(children: [
                // Header
                _GroupHeader(group: group, onBack: () => Navigator.pop(context), currentUserId: me.id),
                // Messages
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: GroupService().listenToGroupMessages(widget.groupId),
                    builder: (ctx, snap) {
                      final msgs = snap.data ?? [];
                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: msgs.length,
                        itemBuilder: (ctx, i) => MessageBubble(
                          message: msgs[i],
                          isMine: msgs[i].senderId == me.id,
                          showAvatar: msgs[i].senderId != me.id,
                          showName: msgs[i].senderId != me.id,
                          onReply: (msg) => setState(() => _replyingTo = msg),
                          onReact: (msg, emoji) => GroupService().addGroupReaction(widget.groupId, msg.id, emoji, me.id),
                          onDelete: group.isAdmin(me.id) ? (msg) => GroupService().deleteGroupMessage(widget.groupId, msg.id) : null,
                        ),
                      );
                    },
                  ),
                ),
                if (_replyingTo != null) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.bgLight,
                  child: Row(children: [
                    Container(width: 3, height: 36, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_replyingTo!.text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted), onPressed: () => setState(() => _replyingTo = null)),
                  ]),
                ),
                GroupInputBar(
                  groupId: widget.groupId,
                  senderId: me.id,
                  senderName: me.name,
                  senderPhotoUrl: me.photoUrl,
                  replyingTo: _replyingTo,
                  onSent: () {
                    setState(() => _replyingTo = null);
                    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                  },
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onBack;
  final String currentUserId;
  const _GroupHeader({required this.group, required this.onBack, required this.currentUserId});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: onBack),
      UserAvatar(photoUrl: group.photoUrl, name: group.name, size: 38),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        Text('${group.members.length} ${AppLocalizations.of(context)['members']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
      IconButton(icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary), onPressed: () {}),
    ]),
  );
}