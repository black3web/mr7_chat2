import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/storage_service.dart';
import '../../services/admin_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
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
                Text(l['support'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 42,
              decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                padding: const EdgeInsets.all(3),
                tabs: [Tab(text: l['sendSupportMessage']), Tab(text: l['supportMessages'])],
              ),
            ),
            Expanded(child: TabBarView(controller: _tabCtrl, children: const [_SendSupportTab(), _SupportThreadsTab()])),
          ]),
        ),
      ),
    );
  }
}

class _SendSupportTab extends StatefulWidget {
  const _SendSupportTab();
  @override
  State<_SendSupportTab> createState() => _SendSupportTabState();
}

class _SendSupportTabState extends State<_SendSupportTab> {
  final _ctrl = TextEditingController();
  List<String> _images = [];
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadSupportImage(file, 'support_temp');
      setState(() => _images.add(url));
    } catch (e) { debugPrint("[Support Screen] Error: $e"); } finally { setState(() => _loading = false); }
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty && _images.isEmpty) return;
    final userId = context.read<AppProvider>().currentUser!.id;
    final userName = context.read<AppProvider>().currentUser!.name;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colSupport).add({
        'userId': userId,
        'userName': userName,
        'message': _ctrl.text.trim(),
        'imageUrls': _images,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'hasUnreadReply': false,
      });
      _ctrl.clear();
      setState(() { _images = []; _sent = true; });
    } catch (e) { debugPrint("[Support Screen] Error: $e"); } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_sent) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_rounded, size: 56, color: AppColors.online),
      const SizedBox(height: 12),
      Text(l['supportSent'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextButton(onPressed: () => setState(() => _sent = false), child: Text(l['send'], style: const TextStyle(color: AppColors.accent))),
    ]));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _ctrl, maxLines: 6, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: l['supportDescription'], border: InputBorder.none)),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _images.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _images[i], width: 80, height: 80, fit: BoxFit.cover)),
              Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => setState(() => _images.removeAt(i)), child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54), child: const Icon(Icons.close_rounded, size: 14, color: Colors.white)))),
            ]))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            GestureDetector(onTap: _pickImage, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.glassBorder)), child: const Icon(Icons.image_rounded, size: 22, color: AppColors.textSecondary))),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loading ? null : _send,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
              label: Text(l['send'], style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ]),
        ])),
      ]),
    );
  }
}

class _SupportThreadsTab extends StatelessWidget {
  const _SupportThreadsTab();
  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppProvider>().currentUser!.id;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.colSupport).where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Icon(Icons.support_agent_rounded, size: 56, color: AppColors.textMuted));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 6),
                if (d['hasUnreadReply'] == true) Row(children: [
                  Icon(Icons.reply_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text('تم الرد', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}