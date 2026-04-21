import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../widgets/dev_crown_badge.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/user_avatar.dart';

class HomeDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeDrawer({super.key, required this.scaffoldKey});

  void _close(BuildContext context) => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();

    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.drawerGradient),
          child: SafeArea(
            child: Column(children: [
              // Profile banner
              GestureDetector(
                onTap: () {
                  _close(context);
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryDark.withOpacity(0.8),
                        AppColors.bgDark.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        photoUrl: user.photoUrl,
                        name: user.name,
                        size: 72,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: ${user.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35),
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 8),
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      label: l['myAccount'],
                      onTap: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.smart_toy_rounded,
                      label: l['aiServices'],
                      onTap: () => _close(context),
                    ),
                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      label: l['settings'],
                      onTap: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.support_agent_rounded,
                      label: l['support'],
                      onTap: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.support);
                      },
                    ),

                    // Admin-only section
                    if (user.isAdmin) ...[const DevCrownBadge(size: 16),
                      Divider(color: AppColors.divider.withOpacity(0.5), height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppGradients.accentGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      _DrawerItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: l['adminPanel'],
                        color: AppColors.accent,
                        onTap: () {
                          _close(context);
                          Navigator.pushNamed(context, AppRoutes.admin);
                        },
                      ),
                    ],

                    Divider(color: AppColors.divider.withOpacity(0.5), height: 20),

                    // Saved accounts
                    if (p.savedAccounts.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(children: [
                          Text(
                            l['switchAccount'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ]),
                      ),
                      ...p.savedAccounts
                          .where((a) => a.id != user.id)
                          .map((acc) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 2),
                                leading: UserAvatar(
                                  photoUrl: acc.photoUrl,
                                  name: acc.name,
                                  size: 38,
                                ),
                                title: Text(
                                  acc.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '@${acc.username}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  _close(context);
                                  p.switchAccount(acc.id);
                                },
                              )),
                      const SizedBox(height: 4),
                    ],

                    _DrawerItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: l['addAccount'],
                      onTap: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                    ),

                    Divider(color: AppColors.divider.withOpacity(0.5), height: 20),

                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: l['devInfo'],
                      onTap: () {
                        _close(context);
                        _showDevInfo(context, l);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: l['logout'],
                      color: AppColors.accent,
                      onTap: () async {
                        _close(context);
                        await p.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDevInfo(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Text(l['devInfo'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 12),
              ],
            ),
            child: const Center(
              child: Text(
                'J',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            AppConstants.devName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '@${AppConstants.devUsername}',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _DevLink(
            icon: Icons.language_rounded,
            label: 'الموقع الشخصي',
            url: AppConstants.devWebsite,
          ),
          const SizedBox(height: 10),
          _DevLink(
            icon: Icons.send_rounded,
            label: 'قناة تيليجرام',
            url: AppConstants.devTelegram,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('اغلاق', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: c),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.withOpacity(0.5)),
        ),
      ),
    );
  }
}

class _DevLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _DevLink({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              )),
              Text(url, style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}