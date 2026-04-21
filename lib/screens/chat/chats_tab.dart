import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class ChatsTab extends StatelessWidget {
  final String filter;
  const ChatsTab({super.key, this.filter = 'all'});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<ChatModel>>(
      stream: ChatService().listenToChats(user.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        var chats = snap.data ?? [];
        if (filter == 'unread') {
          chats = chats.where((c) => (c.unreadCounts[user.id] ?? 0) > 0).toList();
        }
        if (chats.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgLight,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 36, color: AppColors.textMuted.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              Text(l['noChats'],
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 6),
              Text('ابدأ محادثة جديدة',
                  style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.6),
                      fontSize: 13)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: chats.length,
          itemBuilder: (ctx, i) => _ChatTile(
            chat: chats[i],
            currentUserId: user.id,
            isLast: i == chats.length - 1,
          ),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final bool isLast;
  const _ChatTile({
    required this.chat,
    required this.currentUserId,
    this.isLast = false,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes}د';
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return DateFormat('EEEE', 'ar').format(dt);
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final otherId = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId,
    );
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserById(otherId),
      builder: (ctx, snap) {
        final other = snap.data;
        final unread = chat.unreadCounts[currentUserId] ?? 0;
        final hasUnread = unread > 0;

        return InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.chat,
            arguments: {'chatId': chat.id, 'otherUserId': otherId},
          ),
          splashColor: AppColors.accent.withOpacity(0.06),
          highlightColor: AppColors.accent.withOpacity(0.04),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: AppColors.divider.withOpacity(0.5),
                          width: 0.5)),
            ),
            child: Row(children: [
              // Avatar with online dot
              UserAvatar(
                photoUrl: other?.photoUrl,
                name: other?.name ?? '?',
                size: 54,
                showOnline: true,
                isOnline: other?.isOnline ?? false,
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          other?.name ?? '...',
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppColors.accent
                              : AppColors.textMuted,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      // Last message preview
                      Expanded(
                        child: Text(
                          chat.lastMessageText ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unread badge
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppGradients.accentGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
