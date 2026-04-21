import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/ai_chat_widgets.dart';

class VideoGenScreen extends StatefulWidget {
  const VideoGenScreen({super.key});
  @override
  State<VideoGenScreen> createState() => _VideoGenScreenState();
}

class _VideoGenScreenState extends State<VideoGenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          AiScreenHeader(title: 'Video Generator', subtitle: 'AI Video Creation', color: const Color(0xFF9C27B0), icon: Icons.videocam_rounded),
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
              tabs: const [Tab(text: 'Seedance AI'), Tab(text: 'Video AI')],
            ),
          ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: const [_SeedanceTab(), _KilwaVideoTab()])),
        ])),
      ),
    );
  }
}

class _SeedanceTab extends StatefulWidget {
  const _SeedanceTab();
  @override
  State<_SeedanceTab> createState() => _SeedanceTabState();
}

class _SeedanceTabState extends State<_SeedanceTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;
  String? _inputImageUrl;
  bool _imageToVideo = false;
  Map<String, dynamic> _selectedModel = AiService.seedanceModels[0];
  int _duration = 8;
  String _resolution = '720p';
  String _aspectRatio = '16:9';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadMedia(file, 'ai_temp');
      if (mounted) setState(() { _inputImageUrl = url; _imageToVideo = true; });
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل تحميل الصورة.');
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
      final url = await AiService().seedanceGenerate(
        prompt: prompt,
        userId: userId,
        model: _selectedModel['id'] as String,
        duration: _duration,
        resolution: _resolution,
        aspectRatio: _aspectRatio,
        imageUrl: _imageToVideo ? _inputImageUrl : null,
      );
      if (mounted) setState(() => _resultUrl = url);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'فشل توليد الفيديو. حاول مجدداً.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final durations = (_selectedModel['durations'] as List).cast<int>();
    final ratios = (_selectedModel['ratios'] as List).cast<String>();
    final supportsImage = _selectedModel['supportsImageInput'] as bool? ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Model selector
        GlassContainer(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('النموذج', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...AiService.seedanceModels.map((m) => GestureDetector(
            onTap: () { setState(() { _selectedModel = m; if (!durations.contains(_duration)) _duration = (m['durations'] as List).first as int; }); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: _selectedModel['id'] == m['id'] ? AppGradients.accentGradient : null,
                color: _selectedModel['id'] == m['id'] ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedModel['id'] == m['id'] ? AppColors.accent : AppColors.glassBorder),
              ),
              child: Row(children: [
                Icon(Icons.movie_rounded, size: 18, color: _selectedModel['id'] == m['id'] ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['name'] as String, style: TextStyle(color: _selectedModel['id'] == m['id'] ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${(m['durations'] as List).join(', ')}s | ${(m['resolutions'] as List).join(', ')}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                ])),
                if (_selectedModel['id'] == m['id']) const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
              ]),
            ),
          )),
        ])),
        const SizedBox(height: 12),

        // Duration
        Text('المدة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: durations.map((d) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _duration = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(gradient: _duration == d ? AppGradients.accentGradient : null, color: _duration == d ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _duration == d ? AppColors.accent : AppColors.glassBorder)),
                child: Text('${d}s', style: TextStyle(color: _duration == d ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
              ),
            ),
          )).toList(),
        )),
        const SizedBox(height: 12),

        // Aspect Ratio
        Text('نسبة العرض', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
          children: ratios.map((r) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _aspectRatio = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(gradient: _aspectRatio == r ? AppGradients.accentGradient : null, color: _aspectRatio == r ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _aspectRatio == r ? AppColors.accent : AppColors.glassBorder)),
                child: Text(r, style: TextStyle(color: _aspectRatio == r ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          )).toList(),
        )),
        const SizedBox(height: 12),

        // Resolution
        Text('الدقة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: ['480p', '720p'].asMap().entries.map((e) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: e.key == 0 ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _resolution = e.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(gradient: _resolution == e.value ? AppGradients.accentGradient : null, color: _resolution == e.value ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _resolution == e.value ? AppColors.accent : AppColors.glassBorder)),
              child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(color: _resolution == e.value ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          ),
        ))).toList()),
        const SizedBox(height: 12),

        // Image-to-video toggle
        if (supportsImage) ...[
          GestureDetector(
            onTap: _imageToVideo ? () => setState(() { _imageToVideo = false; _inputImageUrl = null; }) : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: _imageToVideo ? AppGradients.accentGradient : null,
                color: _imageToVideo ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _imageToVideo ? AppColors.accent : AppColors.glassBorder),
              ),
              child: Row(children: [
                Icon(_imageToVideo ? Icons.image_rounded : Icons.add_photo_alternate_outlined, size: 20, color: _imageToVideo ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 10),
                Text(_imageToVideo ? 'صورة مُحددة — اضغط للإزالة' : 'أضف صورة (Image → Video)', style: TextStyle(color: _imageToVideo ? Colors.white : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          if (_inputImageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _inputImageUrl!, height: 120, fit: BoxFit.cover, width: double.infinity)),
          ],
          const SizedBox(height: 12),
        ],

        TextField(controller: _ctrl, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 15), decoration: InputDecoration(hintText: l['videoDescription'])),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.movie_creation_rounded, size: 20),
          label: Text(_loading ? l['generating'] : l['generateVideo'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrBox(msg: _error!, onClose: () => setState(() => _error = null)),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          GlassContainer(padding: const EdgeInsets.all(12), child: Column(children: [
            VideoPlayerWidget(url: _resultUrl!),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
              const SizedBox(width: 6),
              const Text('تم توليد الفيديو بنجاح', style: TextStyle(color: AppColors.online, fontSize: 13)),
            ]),
          ])),
        ],
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ملاحظات:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('• Seedance 1.5 Pro: 4/8/12 ثانية', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const Text('• Seedance 1.0 Pro/Lite: 5/10 ثانية', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const Text('• جميع النماذج تدعم Image-to-Video', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _KilwaVideoTab extends StatefulWidget {
  const _KilwaVideoTab();
  @override
  State<_KilwaVideoTab> createState() => _KilwaVideoTabState();
}

class _KilwaVideoTabState extends State<_KilwaVideoTab> {
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
      final url = await AiService().generateVideoKilwa(prompt, userId);
      if (mounted) setState(() => _resultUrl = url);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'فشل توليد الفيديو. حاول مجدداً.');
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
          const Icon(Icons.movie_rounded, size: 48, color: Color(0xFF9C27B0)),
          const SizedBox(height: 8),
          const Text('Video AI - Kilwa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text('توليد فيديو سريع بالذكاء الاصطناعي', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ])),
        const SizedBox(height: 16),
        TextField(controller: _ctrl, maxLines: 4, style: const TextStyle(color: Colors.white, fontSize: 15), decoration: InputDecoration(hintText: l['videoDescription'])),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_circle_rounded, size: 20),
          label: Text(_loading ? 'جاري التوليد... قد يستغرق دقيقتين' : l['generateVideo'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF4A148C), minimumSize: const Size(double.infinity, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrBox(msg: _error!, onClose: () => setState(() => _error = null)),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          GlassContainer(padding: const EdgeInsets.all(8), child: VideoPlayerWidget(url: _resultUrl!)),
        ],
      ]),
    );
  }
}

// ── Shared error box ───────────────────────────────────────────────────────
class _ErrBox extends StatelessWidget {
  final String msg;
  final VoidCallback onClose;
  const _ErrBox({required this.msg, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
      GestureDetector(onTap: onClose, child: const Icon(Icons.close, color: AppColors.textMuted, size: 16)),
    ]),
  );
}

// ── VideoPlayer widget (shared) ────────────────────────────────────────────
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _playing = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
    _ctrl.addListener(() {
      if (mounted) setState(() => _playing = _ctrl.value.isPlaying);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_error) return Container(height: 200, decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 36), SizedBox(height: 8), Text('تعذر تحميل الفيديو', style: TextStyle(color: AppColors.textMuted))])));
    if (!_initialized) return Container(height: 200, decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)), child: const Center(child: CircularProgressIndicator(color: AppColors.accent)));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: [
        AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
        Positioned.fill(child: GestureDetector(
          onTap: () => _playing ? _ctrl.pause() : _ctrl.play(),
          child: AnimatedOpacity(
            opacity: _playing ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(color: Colors.black38, child: const Center(child: Icon(Icons.play_circle_rounded, size: 56, color: Colors.white))),
          ),
        )),
        Positioned(bottom: 0, left: 0, right: 0,
          child: VideoProgressIndicator(_ctrl, allowScrubbing: true,
            colors: VideoProgressColors(playedColor: AppColors.accent, bufferedColor: AppColors.primary.withOpacity(0.4), backgroundColor: Colors.white12))),
      ]),
    );
  }
}
