import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/admin_service.dart';
import '../../services/ai_service.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/animated_background.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    if (!p.isAdmin) return const Scaffold(body: Center(child: Icon(Icons.block_rounded, size: 56, color: AppColors.accent)));
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ShaderMask(
                  shaderCallback: (b) => AppGradients.accentGradient.createShader(b),
                  child: const Text('Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                ),
              ]),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 42,
              decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                padding: const EdgeInsets.all(3),
                tabs: [
                  Tab(text: l['statistics']),
                  Tab(text: l['allUsers']),
                  Tab(text: l['broadcast']),
                  Tab(text: l['aiServices2']),
                ],
              ),
            ),
            Expanded(child: TabBarView(controller: _tabCtrl, children: const [
              _StatsTab(),
              _UsersTab(),
              _BroadcastTab(),
              _AiServicesTab(),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: AdminService().getStatistics(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        final stats = snap.data!;
        final aiBreakdown = (stats['aiBreakdown'] as Map?)?.cast<String, int>() ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(label: l['totalUsers'], value: '${stats['totalUsers'] ?? 0}', icon: Icons.people_rounded, color: const Color(0xFF4285F4)),
                _StatCard(label: l['activeUsers'], value: '${stats['activeUsers'] ?? 0}', icon: Icons.online_prediction_rounded, color: AppColors.online),
                _StatCard(label: l['totalGroups'], value: '${stats['totalGroups'] ?? 0}', icon: Icons.group_rounded, color: const Color(0xFFFF9800)),
                _StatCard(label: l['aiUsage'], value: '${stats['totalAiRequests'] ?? 0}', icon: Icons.auto_awesome_rounded, color: const Color(0xFF9C27B0)),
              ],
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('استخدام الذكاء الاصطناعي', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 12),
                ...aiBreakdown.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(children: [
                    Row(children: [
                      Text(e.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Text('${e.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (stats['totalAiRequests'] ?? 0) > 0 ? e.value / (stats['totalAiRequests'] as int) : 0,
                      backgroundColor: AppColors.bgLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                )),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, size: 24, color: color),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ]),
  );
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  List<UserModel>? _filtered;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white),
          onChanged: (q) async {
            if (q.trim().isEmpty) { setState(() => _filtered = null); return; }
            final results = await AdminService().searchUsers(q.trim());
            setState(() => _filtered = results);
          },
          decoration: InputDecoration(hintText: 'بحث بالاسم او ID...', prefixIcon: const Icon(Icons.search_rounded, size: 20)),
        ),
      ),
      Expanded(
        child: _filtered != null
            ? ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtered!.length,
                itemBuilder: (_, i) => _UserTile(user: _filtered![i]),
              )
            : StreamBuilder<List<UserModel>>(
                stream: AdminService().getAllUsers(),
                builder: (ctx, snap) {
                  final users = snap.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (_, i) => _UserTile(user: users[i]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});
  @override
  Widget build(BuildContext context) => GlassContainer(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Stack(children: [
        UserAvatar(photoUrl: user.photoUrl, name: user.name, size: 44),
        if (user.isAdmin) Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD700), border: Border.all(color: AppColors.bgDark)), child: const Icon(Icons.star_rounded, size: 9, color: Colors.black))),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          if (user.isBanned) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.accent.withOpacity(0.4))), child: const Text('محظور', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        Text('@${user.username} | ${user.id}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace')),
      ])),
      IconButton(
        icon: Icon(user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded, color: user.isBanned ? AppColors.online : AppColors.accent, size: 20),
        onPressed: () => AdminService().toggleBanUser(user.id, !user.isBanned),
      ),
    ]),
  );
}

class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();
  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _titleCtrl.dispose(); _msgCtrl.dispose(); _linkCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final me = context.read<AppProvider>().currentUser!;
    try {
      await AdminService().sendBroadcast(title: _titleCtrl.text.trim(), message: _msgCtrl.text.trim(), link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(), senderId: me.id);
      _titleCtrl.clear(); _msgCtrl.clear(); _linkCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ارسال الاذاعة')));
    } catch (e) { debugPrint("[Admin Screen] Error: $e"); } finally { setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('اذاعة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'العنوان (اختياري)', prefixIcon: Icon(Icons.title_rounded, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: _msgCtrl, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'نص الاذاعة...', prefixIcon: Icon(Icons.campaign_rounded, size: 20))),
          const SizedBox(height: 12),
          TextField(controller: _linkCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'رابط (اختياري)', prefixIcon: Icon(Icons.link_rounded, size: 20))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
            label: const Text('ارسال للجميع', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ])),
      ]),
    );
  }
}

class _AiServicesTab extends StatefulWidget {
  const _AiServicesTab();
  @override
  State<_AiServicesTab> createState() => _AiServicesTabState();
}

class _AiServicesTabState extends State<_AiServicesTab> {
  Map<String, bool> _states = {};
  bool _loading = true;

  static const Map<String, String> _serviceNames = {
    'gemini':        'Gemini 2.5 Flash',
    'deepseek':      'DeepSeek AI',
    'imageGen':      'Nano Banana 2',
    'nanoBananaPro': 'NanoBanana Pro',
    'seedance':      'Seedance AI',
    'kilwaVideo':    'Video AI',
    'musicAi':       'AI Music',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final states = await AiService().getServiceStates();
    setState(() { _states = states; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _serviceNames.entries.map((e) => GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: (_states[e.key] ?? true) ? AppColors.primary.withOpacity(0.2) : AppColors.bgLight, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.auto_awesome_rounded, size: 20, color: (_states[e.key] ?? true) ? AppColors.accent : AppColors.textMuted)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            Text((_states[e.key] ?? true) ? 'نشط' : 'معطل', style: TextStyle(fontSize: 12, color: (_states[e.key] ?? true) ? AppColors.online : AppColors.accent)),
          ])),
          Switch(
            value: _states[e.key] ?? true,
            onChanged: (v) async {
              await AiService().toggleService(e.key, v);
              setState(() => _states[e.key] = v);
            },
            activeColor: AppColors.accent,
          ),
        ]),
      )).toList(),
    );
  }
}