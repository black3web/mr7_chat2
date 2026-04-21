import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'message_bubble.dart';
import 'chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  UserModel? _otherUser;
  MessageModel? _replyingTo;
  final _scrollCtrl = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _markRead();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 400;
      if (show != _showScrollFab) setState(() => _showScrollFab = show);
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getUserById(widget.otherUserId);
    if (mounted) setState(() => _otherUser = user);
  }

  void _markRead() {
    final uid = context.read<AppProvider>().currentUser?.id;
    if (uid != null) {
      ChatService().markAsRead(widget.chatId, uid).catchError((_) {});
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final me = p.currentUser!;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
          image: p.chatBackground != null
              ? DecorationImage(
                  image: NetworkImage(p.chatBackground!),
                  fit: BoxFit.cover,
                  opacity: 0.14,
                )
              : null,
        ),
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              // Header
              _ChatHeader(
                user: _otherUser,
                onBack: () => Navigator.pop(context),
                onCall: () => _showComingSoon(context, 'المكالمات الصوتية'),
                onVideo: () => _showComingSoon(context, 'مكالمات الفيديو'),
              ),

              // Messages
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: ChatService().listenToMessages(widget.chatId),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                      );
                    }
                    final msgs = snap.data ?? [];
                    if (msgs.isEmpty) {
                      return _EmptyChat(name: _otherUser?.name);
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: msgs.length,
                      itemBuilder: (ctx, i) {
                        final msg = msgs[i];
                        final nextMsg = i > 0 ? msgs[i - 1] : null;
                        final showAvatar = !msg.senderId.contains(me.id) &&
                            (nextMsg == null || nextMsg.senderId != msg.senderId);
                        return MessageBubble(
                          key: ValueKey(msg.id),
                          message: msg,
                          isMine: msg.senderId == me.id,
                          showAvatar: showAvatar,
                          showName: showAvatar,
                          onReply: (m) => setState(() => _replyingTo = m),
                          onDelete: (m) => _confirmDelete(context, l, m),
                          onEdit: (m) => _showEdit(context, l, m),
                          onReact: (m, emoji) =>
                              ChatService().addReaction(widget.chatId, m.id, emoji, me.id),
                        );
                      },
                    );
                  },
                ),
              ),

              // ✅ FIX: Reply preview is now INSIDE ChatInputBar (removed duplicate here)
              // Input bar — pass replyingTo and onClearReply
              ChatInputBar(
                chatId: widget.chatId,
                senderId: me.id,
                senderName: me.name,
                senderPhotoUrl: me.photoUrl,
                replyingTo: _replyingTo,
                onClearReply: () => setState(() => _replyingTo = null),
                onSent: () {
                  setState(() => _replyingTo = null);
                  _scrollToBottom();
                },
              ),
            ]),

            // Scroll FAB
            if (_showScrollFab)
              Positioned(
                right: 16,
                bottom: 80,
                child: GestureDetector(
                  onTap: _scrollToBottom,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgElevated,
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature قادمة قريباً'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l, MessageModel m) async {
    final del = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l['deleteMessage'], style: const TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف الرسالة؟',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l['cancel'])),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l['delete']),
          ),
        ],
      ),
    );
    if (del == true) {
      ChatService().deleteMessage(widget.chatId, m.id).catchError((_) {});
    }
  }

  Future<void> _showEdit(BuildContext context, AppLocalizations l, MessageModel m) async {
    final ctrl = TextEditingController(text: m.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l['editMessage'], style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'تعديل الرسالة...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l['cancel'])),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text(l['save']),
          ),
        ],
      ),
    );
    if (newText != null && newText.trim().isNotEmpty) {
      ChatService().editMessage(widget.chatId, m.id, newText.trim()).catchError((_) {});
    }
  }
}

// ─── Empty Chat ──────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final String? name;
  const _EmptyChat({this.name});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgLight,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(Icons.waving_hand_rounded, size: 36, color: AppColors.accent),
      ),
      const SizedBox(height: 16),
      Text(
        name != null ? 'ابدأ المحادثة مع $name' : 'قل مرحباً 👋',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      const SizedBox(height: 6),
      Text(
        'الرسائل مشفرة وآمنة',
        style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 12),
      ),
    ]),
  );
}

// ─── Chat Header ─────────────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onVideo;
  const _ChatHeader({this.user, required this.onBack, required this.onCall, required this.onVideo});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgMedium.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary),
          onPressed: onBack,
        ),
        Expanded(
          child: GestureDetector(
            onTap: user != null
                ? () => Navigator.pushNamed(context, AppRoutes.userProfile, arguments: {'userId': user!.id})
                : null,
            child: Row(children: [
              UserAvatar(
                photoUrl: user?.photoUrl,
                name: user?.name ?? '?',
                size: 38,
                showOnline: true,
                isOnline: user?.isOnline ?? false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    user?.name ?? '...',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: user?.isOnline == true ? AppColors.online : AppColors.offline,
                      ),
                    ),
                    Text(
                      user?.isOnline == true ? l['online'] : l['offline'],
                      style: TextStyle(
                        fontSize: 11,
                        color: user?.isOnline == true ? AppColors.online : AppColors.textMuted,
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.textSecondary, size: 22),
          onPressed: onVideo,
          tooltip: 'مكالمة فيديو',
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.textSecondary, size: 20),
          onPressed: onCall,
          tooltip: 'مكالمة صوتية',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'profile', child: Text('عرض الملف الشخصي')),
            const PopupMenuItem(value: 'search', child: Text('بحث في الرسائل')),
            const PopupMenuItem(value: 'clear', child: Text('مسح المحادثة')),
            const PopupMenuItem(value: 'block', child: Text('حظر المستخدم')),
          ],
          onSelected: (v) {
            if (v == 'profile' && user != null) {
              Navigator.pushNamed(context, AppRoutes.userProfile, arguments: {'userId': user!.id});
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$v قادمة قريباً'), behavior: SnackBarBehavior.floating),
              );
            }
          },
        ),
      ]),
    );
  }
}
