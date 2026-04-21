import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/animated_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.bgMedium,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18), onPressed: () => Navigator.pop(context)),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'edit') Navigator.pushNamed(context, AppRoutes.editProfile);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary), const SizedBox(width: 10), Text(l['editProfile'], style: const TextStyle(color: Colors.white))])),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: AppGradients.drawerGradient),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: user.photoUrl != null ? () => _showPhoto(context, user.photoUrl!) : null,
                      child: Hero(tag: 'profile_photo', child: UserAvatar(photoUrl: user.photoUrl, name: user.name, size: 90)),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('@${user.username}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                  ]),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _InfoRow(icon: Icons.badge_rounded, label: 'ID', value: user.id, copyable: true),
                    const Divider(color: AppColors.divider, height: 20),
                    _InfoRow(icon: Icons.alternate_email_rounded, label: l['username'], value: '@${user.username}', copyable: true),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const Divider(color: AppColors.divider, height: 20),
                      _InfoRow(icon: Icons.info_outline_rounded, label: 'Bio', value: user.bio!),
                    ],
                  ]),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: Column(children: [
                    ListTile(
                      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit_rounded, size: 20, color: AppColors.accent)),
                      title: Text(l['editProfile'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                    ),
                    ListTile(
                      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.settings_rounded, size: 20, color: AppColors.textSecondary)),
                      title: Text(l['settings'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    ListTile(
                      leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, size: 20, color: AppColors.accent)),
                      title: Text(l['logout'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                      onTap: () async { await p.logout(); Navigator.pushReplacementNamed(context, AppRoutes.login); },
                    ),
                  ]),
                ),
              ])),
            ),
          ]),
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) => showDialog(
    context: context,
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: PhotoView(imageProvider: NetworkImage(url), heroAttributes: const PhotoViewHeroAttributes(tag: 'profile_photo'), minScale: PhotoViewComputedScale.contained, maxScale: PhotoViewComputedScale.covered * 3),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool copyable;
  const _InfoRow({required this.icon, required this.label, required this.value, this.copyable = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.textMuted),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    ]),
    const Spacer(),
    if (copyable) GestureDetector(
      onTap: () { Clipboard.setData(ClipboardData(text: value)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1))); },
      child: Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
    ),
  ]);
}