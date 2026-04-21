import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../services/music_ai_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/ai_chat_widgets.dart';

class MusicAiScreen extends StatefulWidget {
  const MusicAiScreen({super.key});
  @override
  State<MusicAiScreen> createState() => _MusicAiScreenState();
}

class _MusicAiScreenState extends State<MusicAiScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String _selectedTag  = 'sad';
  bool _loading        = false;
  String? _audioUrl;
  String? _error;
  VideoPlayerController? _player;
  bool _playerReady    = false;
  bool _playing        = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player?.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _audioUrl = null; _error = null; _playerReady = false; });
    _player?.dispose();
    _player = null;
    try {
      final url = await MusicAiService().generateMusic(prompt: prompt, userId: userId, tag: _selectedTag);
      await _initPlayer(url);
      if (mounted) setState(() => _audioUrl = url);
    } catch (e) {
      if (mounted) {
        // ✅ Show actual error from service
        final msg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'فشل توليد الموسيقى. حاول مجدداً.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initPlayer(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize().timeout(const Duration(seconds: 20));
      ctrl.addListener(() {
        if (mounted) setState(() => _playing = ctrl.value.isPlaying);
      });
      _player = ctrl;
      if (mounted) setState(() => _playerReady = true);
    } catch (e) {
      debugPrint('[MusicAI] Player init: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          AiScreenHeader(
            title: 'AI Music Generator',
            subtitle: 'Visco AI Music',
            color: const Color(0xFF9C27B0),
            icon: Icons.music_note_rounded,
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
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)])),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              padding: const EdgeInsets.all(3),
              tabs: const [Tab(text: 'توليد موسيقى'), Tab(text: 'السجل')],
            ),
          ),
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            children: [_buildGenerateTab(), _buildHistoryTab(userId)],
          )),
        ])),
      ),
    );
  }

  Widget _buildGenerateTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.label_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('نوع الموسيقى', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: MusicAiService.supportedTags.map((tag) {
              final sel = _selectedTag == tag['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedTag = tag['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: sel ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]) : null,
                    color: sel ? null : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? const Color(0xFF9C27B0) : AppColors.glassBorder),
                    boxShadow: sel ? [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.3), blurRadius: 8)] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_tagIcon(tag['id']!), size: 16, color: sel ? Colors.white : AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(tag['label']!, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('وصف الموسيقى', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
            decoration: const InputDecoration(hintText: 'مثال: اغنية حزينة عن الفراق والبعد...', border: InputBorder.none),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loading ? null : _generate,
        icon: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.music_note_rounded, size: 20),
        label: Text(_loading ? 'جاري التوليد...' : 'توليد الموسيقى',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF7B1FA2),
          minimumSize: const Size(double.infinity, 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
            GestureDetector(onTap: () => setState(() => _error = null), child: const Icon(Icons.close, color: AppColors.textMuted, size: 16)),
          ]),
        ),
      ],
      if (_playerReady && _audioUrl != null) ...[
        const SizedBox(height: 16),
        _AudioPlayer(player: _player!, playing: _playing, tag: _selectedTag, onToggle: () {
          _playing ? _player?.pause() : _player?.play();
        }),
      ],
    ]),
  );

  Widget _buildHistoryTab(String userId) => StreamBuilder<List<Map<String, dynamic>>>(
    stream: MusicAiService().getUserMusicHistory(userId),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
      final items = snap.data!;
      if (items.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.music_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
        const SizedBox(height: 12),
        const Text('لا يوجد سجل موسيقى بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
      ]));
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item  = items[i];
          final extra = item['extra'] as Map? ?? {};
          return GlassContainer(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF9C27B0).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.music_note_rounded, size: 22, color: Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['prompt'] as String? ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(extra['tag'] as String? ?? '', style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 11)),
              ])),
              if (extra['audioUrl'] != null)
                IconButton(
                  icon: const Icon(Icons.play_circle_rounded, size: 28, color: Color(0xFF9C27B0)),
                  onPressed: () async {
                    await _initPlayer(extra['audioUrl'] as String);
                    _tabCtrl.animateTo(0);
                  },
                ),
            ]),
          );
        },
      );
    },
  );

  IconData _tagIcon(String t) {
    switch (t) {
      case 'sad':      return Icons.sentiment_very_dissatisfied_rounded;
      case 'happy':    return Icons.sentiment_very_satisfied_rounded;
      case 'romantic': return Icons.favorite_rounded;
      case 'energetic':return Icons.bolt_rounded;
      default:         return Icons.music_note_rounded;
    }
  }
}

class _AudioPlayer extends StatelessWidget {
  final VideoPlayerController player;
  final bool playing;
  final String tag;
  final VoidCallback onToggle;
  const _AudioPlayer({required this.player, required this.playing, required this.tag, required this.onToggle});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    borderColor: const Color(0xFF9C27B0).withOpacity(0.4),
    child: Column(children: [
      Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.music_note_rounded, size: 26, color: Colors.white),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الموسيقى المولدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          Text('AI Generated', style: TextStyle(color: Color(0xFF9C27B0), fontSize: 12)),
        ])),
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.4), blurRadius: 12)],
            ),
            child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      ValueListenableBuilder(
        valueListenable: player,
        builder: (_, value, __) {
          final pos = value.position;
          final dur = value.duration;
          final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
          return Column(children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF9C27B0),
                inactiveTrackColor: AppColors.bgLight,
                thumbColor: const Color(0xFF9C27B0),
                overlayColor: const Color(0xFF9C27B0).withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                trackHeight: 3,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) => player.seekTo(Duration(milliseconds: (v * dur.inMilliseconds).round())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                Text(_fmt(pos), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const Spacer(),
                Text(_fmt(dur), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
          ]);
        },
      ),
    ]),
  );
}
