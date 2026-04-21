import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _confirmLogout = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.watch<AppProvider>();
    final user = p.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0005), Color(0xFF0A0A0A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: Column(children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgMedium.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Text(l['settings'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),

          // ── Body ──
          Expanded(child: ListView(
            padding: const EdgeInsets.all(14),
            children: [

              // ── Appearance section ──
              _sectionTitle(l['appearance']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                // Theme mode
                _SettingsTile(
                  icon: Icons.palette_rounded,
                  iconColor: const Color(0xFF7B1FA2),
                  title: l['theme'],
                  trailing: DropdownButton<String>(
                    value: p.theme,
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'dark', child: Text(l['dark'])),
                      DropdownMenuItem(value: 'light', child: Text(l['light'])),
                      DropdownMenuItem(value: 'system', child: Text(l['system'])),
                    ],
                    onChanged: (v) => p.setTheme(v!),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                // Primary color
                _SettingsTile(
                  icon: Icons.color_lens_rounded,
                  iconColor: AppColors.accent,
                  title: l['accentColor'],
                  trailing: SizedBox(
                    width: 140,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final c in _accentColors) ...[
                          _ColorDot(
                            color: c,
                            selected: p.accentColorValue == c.value,
                            onTap: () => p.setAccentColor(c),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ]),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                // Font size
                _SettingsTile(
                  icon: Icons.text_fields_rounded,
                  iconColor: const Color(0xFF1976D2),
                  title: l['fontSize'],
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => p.setFontScale((p.fontScale - 0.1).clamp(0.8, 1.4)),
                    ),
                    Text('${(p.fontScale * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () => p.setFontScale((p.fontScale + 0.1).clamp(0.8, 1.4)),
                    ),
                  ]),
                ),
              ])),

              // ── Language section ──
              _sectionTitle(l['language']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF00897B),
                  title: l['language'],
                  trailing: DropdownButton<String>(
                    value: p.language,
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Row(children: [Text('🇮🇶  '), Text('العربية')])),
                      DropdownMenuItem(value: 'en', child: Row(children: [Text('🇬🇧  '), Text('English')])),
                    ],
                    onChanged: (v) => p.setLanguage(v!),
                  ),
                ),
              ])),

              // ── Chat section ──
              _sectionTitle('الدردشة'),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFFFA000),
                  title: l['notifications'],
                  trailing: Switch(
                    value: user?.settings['notifications'] ?? true,
                    onChanged: (v) async {
                      await AuthService().updateProfile(settings: {'notifications': v});
                      if (mounted) context.read<AppProvider>().refreshUser();
                    },
                    activeColor: AppColors.accent,
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.done_all_rounded,
                  iconColor: AppColors.read,
                  title: l['readReceipts'],
                  trailing: Switch(
                    value: user?.settings['readReceipts'] ?? true,
                    onChanged: (v) async {
                      await AuthService().updateProfile(settings: {'readReceipts': v});
                      if (mounted) context.read<AppProvider>().refreshUser();
                    },
                    activeColor: AppColors.accent,
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.keyboard_rounded,
                  iconColor: const Color(0xFF546E7A),
                  title: 'مؤشر الكتابة',
                  trailing: Switch(
                    value: user?.settings['typingIndicator'] ?? true,
                    onChanged: (v) async {
                      await AuthService().updateProfile(settings: {'typingIndicator': v});
                      if (mounted) context.read<AppProvider>().refreshUser();
                    },
                    activeColor: AppColors.accent,
                  ),
                ),
              ])),

              // ── Privacy section ──
              _sectionTitle(l['privacy']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _SettingsTile(
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFF00897B),
                  title: l['lastSeen'],
                  trailing: DropdownButton<String>(
                    value: user?.privacy['lastSeen'] ?? 'everyone',
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'everyone', child: Text('الجميع')),
                      DropdownMenuItem(value: 'contacts', child: Text('جهات الاتصال')),
                      DropdownMenuItem(value: 'nobody', child: Text('لا أحد')),
                    ],
                    onChanged: (v) async {
                      await AuthService().updateProfile(privacy: {'lastSeen': v});
                      if (mounted) context.read<AppProvider>().refreshUser();
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.photo_rounded,
                  iconColor: const Color(0xFF5C6BC0),
                  title: 'صورة الملف الشخصي',
                  trailing: DropdownButton<String>(
                    value: user?.privacy['photo'] ?? 'everyone',
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'everyone', child: Text('الجميع')),
                      DropdownMenuItem(value: 'contacts', child: Text('جهات الاتصال')),
                      DropdownMenuItem(value: 'nobody', child: Text('لا أحد')),
                    ],
                    onChanged: (v) async {
                      await AuthService().updateProfile(privacy: {'photo': v});
                      if (mounted) context.read<AppProvider>().refreshUser();
                    },
                  ),
                ),
              ])),

              // ── Account section ──
              _sectionTitle(l['account']),
              GlassContainer(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
                _SettingsTile(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.accent,
                  title: l['editProfile'],
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                const Divider(height: 1, color: AppColors.divider, indent: 56),
                _SettingsTile(
                  icon: Icons.headset_mic_rounded,
                  iconColor: const Color(0xFF0288D1),
                  title: l['support'],
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.support),
                ),
              ])),

              const SizedBox(height: 8),

              // Logout
              GlassContainer(
                padding: EdgeInsets.zero,
                borderColor: AppColors.accent.withOpacity(0.3),
                child: ListTile(
                  leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.accent)),
                  title: Text(l['logout'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14)),
                  onTap: () async {
                    if (!_confirmLogout) {
                      setState(() => _confirmLogout = true);
                      Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _confirmLogout = false); });
                      return;
                    }
                    await context.read<AppProvider>().logout();
                    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  subtitle: _confirmLogout
                    ? Text('اضغط مجدداً للتأكيد', style: TextStyle(color: AppColors.accent.withOpacity(0.7), fontSize: 11))
                    : null,
                ),
              ),

              const SizedBox(height: 24),

              // App version
              Center(child: Text('MR7 Chat v1.0.0', style: TextStyle(color: AppColors.textMuted.withOpacity(0.4), fontSize: 11))),
              const SizedBox(height: 8),
            ],
          )),
        ])),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
    child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.2)),
  );

  static const List<Color> _accentColors = [
    Color(0xFFFF1744),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF0288D1),
    Color(0xFF00897B),
    Color(0xFFFF6D00),
  ];
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
          if (trailing != null) trailing!,
        ]),
      ),
    ),
  );
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : null,
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
    ),
  );
}