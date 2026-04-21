import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/animated_background.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final user = await AuthService().getUserById(widget.userId);
    setState(() { _user = user; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final me = p.currentUser!;
    final isContact = me.contacts.contains(widget.userId);
    final isBlocked = me.blocked.contains(widget.userId);
    if (_loading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: AppColors.accent)));
    if (_user == null) return Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text(l['noResults'], style: const TextStyle(color: AppColors.textMuted))));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                Text(_user!.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'block') { await AuthService().toggleBlock(widget.userId); p.refreshUser(); setState((){}); }
                    if (v == 'contact') { await AuthService().toggleContact(widget.userId); p.refreshUser(); setState((){}); }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'contact', child: Row(children: [Icon(isContact ? Icons.person_remove_rounded : Icons.person_add_rounded, size: 18, color: AppColors.textSecondary), const SizedBox(width: 10), Text(isContact ? l['removeContact'] : l['addContact'], style: const TextStyle(color: Colors.white))])),
                    PopupMenuItem(value: 'block', child: Row(children: [Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18, color: AppColors.accent), const SizedBox(width: 10), Text(isBlocked ? l['unblock'] : l['block'], style: const TextStyle(color: AppColors.accent))])),
                  ],
                ),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
              Center(child: UserAvatar(photoUrl: _user!.photoUrl, name: _user!.name, size: 90)),
              const SizedBox(height: 12),
              Text(_user!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('@${_user!.username}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _user!.isOnline ? AppColors.online : AppColors.offline)),
                const SizedBox(width: 6),
                Text(_user!.isOnline ? l['online'] : l['offline'], style: TextStyle(color: _user!.isOnline ? AppColors.online : AppColors.textMuted, fontSize: 13)),
              ]),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final chat = await ChatService().getOrCreateChat(me.id, widget.userId);
                  Navigator.pushReplacementNamed(context, AppRoutes.chat, arguments: {'chatId': chat.id, 'otherUserId': widget.userId});
                },
                icon: const Icon(Icons.message_rounded, size: 18),
                label: Text(l['chats'], style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
                _Row(icon: Icons.badge_rounded, label: 'ID', value: _user!.id),
                const Divider(color: AppColors.divider, height: 20),
                _Row(icon: Icons.alternate_email_rounded, label: l['username'], value: '@${_user!.username}'),
              ])),
            ]))),
          ]),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textMuted),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  ]);
}