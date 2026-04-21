import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/ai_chat_widgets.dart';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});
  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> with SingleTickerProviderStateMixin {
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          AiScreenHeader(
            title: 'Image Generator',
            subtitle: 'AI Image Creation',
            color: const Color(0xFFE91E63),
            icon: Icons.image_rounded,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              padding: const EdgeInsets.all(3),
              tabs: [Tab(text: l['generateImage']), Tab(text: l['imageEditing'])],
            ),
          ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: const [_NanoBananaTab(), _NanoBananaProTab()])),
        ])),
      ),
    );
  }
}

// ── Nano Banana 2 — text-to-image ─────────────────────────────────────────
class _NanoBananaTab extends StatefulWidget {
  const _NanoBananaTab();
  @override
  State<_NanoBananaTab> createState() => _NanoBananaTabState();
}

class _NanoBananaTabState extends State<_NanoBananaTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _resultUrl = null; _error = null; });
    try {
      final url = await AiService().generateImageNano(prompt, userId);
      if (mounted) setState(() => _resultUrl = url);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'فشل توليد الصورة. حاول مجدداً.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.image_search_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('Nano Banana 2 - جودة 2K', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _generate(),
              decoration: InputDecoration(hintText: l['imageDescription']),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_fix_high_rounded, size: 20),
              label: Text(_loading ? l['generating'] : l['generateImage'], style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!, onDismiss: () => setState(() => _error = null)),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          _ResultImage(url: _resultUrl!, label: 'تم توليد الصورة بنجاح - جودة 2K'),
        ],
      ]),
    );
  }
}

// ── NanoBanana Pro — create + edit ────────────────────────────────────────
class _NanoBananaProTab extends StatefulWidget {
  const _NanoBananaProTab();
  @override
  State<_NanoBananaProTab> createState() => _NanoBananaProTabState();
}

class _NanoBananaProTabState extends State<_NanoBananaProTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;
  String? _inputImageUrl;
  String _ratio = '1:1';
  String _resolution = '2K';
  bool _editMode = false;

  static const _ratios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const _resolutions = ['1K', '2K', '4K'];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadMedia(file, 'ai_temp');
      if (mounted) setState(() { _inputImageUrl = url; _editMode = true; });
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل تحميل الصورة. تحقق من الاتصال.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _resultUrl = null; _error = null; });
    try {
      final url = await AiService().nanoBananaPro(
        prompt: prompt, userId: userId,
        ratio: _ratio, resolution: _resolution,
        imageUrl: _inputImageUrl,
      );
      if (mounted) setState(() => _resultUrl = url);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'فشل معالجة الصورة. حاول مجدداً.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Mode toggle
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() { _editMode = false; _inputImageUrl = null; }),
            child: _ModeBtn(icon: Icons.text_fields_rounded, label: l['generateImage'], active: !_editMode, side: 'left'),
          )),
          Expanded(child: GestureDetector(
            onTap: _pickImage,
            child: _ModeBtn(icon: Icons.photo_filter_rounded, label: l['editImage'], active: _editMode, side: 'right'),
          )),
        ]),
        const SizedBox(height: 12),

        // Input image preview
        if (_inputImageUrl != null) ...[
          Stack(children: [
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(imageUrl: _inputImageUrl!, height: 160, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Positioned(top: 12, right: 12, child: GestureDetector(
              onTap: () => setState(() { _inputImageUrl = null; _editMode = false; }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            )),
          ]),
          const SizedBox(height: 12),
        ],

        // Ratio selector
        _SectionLabel('نسبة الصورة'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _ratios.map((r) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(label: r, selected: _ratio == r, onTap: () => setState(() => _ratio = r)),
          )).toList()),
        ),
        const SizedBox(height: 12),

        // Resolution selector
        _SectionLabel('الجودة'),
        const SizedBox(height: 8),
        Row(children: _resolutions.asMap().entries.map((e) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: e.key < _resolutions.length - 1 ? 8 : 0),
          child: _Chip(label: e.value, selected: _resolution == e.value, onTap: () => setState(() => _resolution = e.value), expand: true),
        ))).toList()),
        const SizedBox(height: 12),

        TextField(
          controller: _ctrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: _editMode ? 'اكتب تعليمات التعديل...' : l['imageDescription']),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_fix_high_rounded, size: 20),
          label: Text(
            _loading ? l['generating'] : (_editMode ? l['editImage'] : l['generateImage']),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!, onDismiss: () => setState(() => _error = null)),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          _ResultImage(url: _resultUrl!, label: 'تم المعالجة بنجاح - $_resolution'),
        ],
      ]),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;
  const _Chip({required this.label, required this.selected, required this.onTap, this.expand = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: expand ? 0 : 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.accentGradient : null,
        color: selected ? null : AppColors.bgLight,
        borderRadius: BorderRadius.circular(expand ? 12 : 20),
        border: Border.all(color: selected ? AppColors.accent : AppColors.glassBorder),
      ),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}

class _ModeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String side;
  const _ModeBtn({required this.icon, required this.label, required this.active, required this.side});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      gradient: active ? AppGradients.accentGradient : null,
      color: active ? null : AppColors.bgLight,
      borderRadius: BorderRadius.horizontal(
        left: side == 'left' ? const Radius.circular(12) : Radius.zero,
        right: side == 'right' ? const Radius.circular(12) : Radius.zero,
      ),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 18, color: active ? Colors.white : AppColors.textMuted),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBox({required this.message, required this.onDismiss});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
      GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, color: AppColors.textMuted, size: 16)),
    ]),
  );
}

class _ResultImage extends StatelessWidget {
  final String url;
  final String label;
  const _ResultImage({required this.url, required this.label});
  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(8),
    child: Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, __) => Container(
            height: 200,
            color: AppColors.bgLight,
            child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 200,
            color: AppColors.bgLight,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted)),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.online, fontSize: 13)),
      ]),
    ]),
  );
}
