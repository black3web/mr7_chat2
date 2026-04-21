import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/kilwa_video_service.dart';
import '../../widgets/glass_container.dart';

class KilwaVideoScreen extends StatefulWidget {
  const KilwaVideoScreen({super.key});

  @override
  State<KilwaVideoScreen> createState() => _KilwaVideoScreenState();
}

class _KilwaVideoScreenState extends State<KilwaVideoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;
  String? _videoUrl;
  String? _error;
  VideoPlayerController? _player;
  bool _playerReady = false;
  bool _playing = false;
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

    _player?.dispose();
    _player = null;
    setState(() {
      _loading = true;
      _videoUrl = null;
      _error = null;
      _playerReady = false;
    });

    try {
      final url = await KilwaVideoService().generateVideo(
        prompt: prompt,
        userId: userId,
      );
      await _initPlayer(url);
      setState(() => _videoUrl = url);
    } catch (e) {
      setState(() => _error = 'فشل توليد الفيديو. حاول مجددا.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _initPlayer(String url) async {
    _player = VideoPlayerController.networkUrl(Uri.parse(url));
    await _player!.initialize();
    _player!.addListener(() {
      if (mounted) setState(() => _playing = _player!.value.isPlaying);
    });
    if (mounted) setState(() => _playerReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgMedium.withOpacity(0.95),
                border:
                    Border(bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded,
                      size: 22, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Video AI',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white)),
                    Text('Seedance Pro',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF1976D2))),
                  ],
                ),
              ]),
            ),

            // Tabs
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                padding: const EdgeInsets.all(3),
                tabs: const [
                  Tab(text: 'توليد فيديو'),
                  Tab(text: 'السجل'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildGenerateTab(),
                  _buildHistoryTab(userId),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          GlassContainer(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF1976D2).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 22,
                    color: Color(0xFF1976D2)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seedance Pro',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text('نموذج توليد فيديو سريع وعالي الجودة',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // Prompt
          TextField(
            controller: _ctrl,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 15,
                height: 1.5),
            decoration: const InputDecoration(
              hintText:
                  'صف الفيديو الذي تريد توليده...\nمثال: هاكر يعمل في غرفة مظلمة مع أضواء نيون',
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.movie_creation_rounded, size: 20),
            label: Text(
              _loading ? 'جاري التوليد...' : 'توليد الفيديو',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF1565C0),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor:
                  const Color(0xFF1976D2).withOpacity(0.4),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 13)),
                ),
              ]),
            ),
          ],

          if (_playerReady && _videoUrl != null) ...[
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              borderColor:
                  const Color(0xFF1976D2).withOpacity(0.4),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(children: [
                    AspectRatio(
                      aspectRatio:
                          _player!.value.aspectRatio,
                      child: VideoPlayer(_player!),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          _playing
                              ? _player?.pause()
                              : _player?.play();
                        },
                        child: AnimatedOpacity(
                          opacity: _playing ? 0 : 1,
                          duration:
                              const Duration(milliseconds: 200),
                          child: Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                VideoProgressIndicator(
                  _player!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF1976D2),
                    bufferedColor: Color(0x401976D2),
                    backgroundColor: AppColors.bgLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.online),
                    const SizedBox(width: 6),
                    Text('تم توليد الفيديو بنجاح',
                        style: TextStyle(
                            color: AppColors.online,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: KilwaVideoService().getUserVideoHistory(userId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1976D2)));
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_rounded,
                    size: 56,
                    color: AppColors.textMuted.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text('لا يوجد سجل فيديو بعد',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 15)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    size: 22,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['prompt'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}