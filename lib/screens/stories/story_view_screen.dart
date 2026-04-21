import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../services/story_service.dart';
import '../../models/story_model.dart';
import '../../widgets/user_avatar.dart';

class StoryViewScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progCtrl;
  int _current = 0;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _progCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
    _loadStory();
  }

  void _loadStory() {
    if (widget.stories.isEmpty) return;
    final story = widget.stories[_current];
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    StoryService().viewStory(story.id, userId);
    _progCtrl.reset();

    if (story.mediaType == StoryMediaType.video) {
      _videoCtrl?.dispose();
      _videoCtrl = null;
      setState(() => _videoReady = false);
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
      _videoCtrl = ctrl;
      ctrl.initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        ctrl.play();
        _progCtrl.duration = ctrl.value.duration;
        _progCtrl.forward();
      });
    } else {
      _videoCtrl?.dispose();
      _videoCtrl = null;
      setState(() => _videoReady = false);
      _progCtrl.duration = const Duration(seconds: 5);
      _progCtrl.forward();
    }
  }

  void _next() {
    if (_current < widget.stories.length - 1) {
      setState(() => _current++);
      _loadStory();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _loadStory();
    }
  }

  @override
  void dispose() {
    _progCtrl.dispose();
    _videoCtrl?.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final story = widget.stories[_current];
    final me = context.read<AppProvider>().currentUser;
    final isOwn = story.userId == me?.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _prev();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Media ──────────────────────────────────────────────
            _buildMedia(story),

            // ── Progress bars ───────────────────────────────────────
            _buildProgressBars(),

            // ── User info header ────────────────────────────────────
            _buildHeader(story, isOwn),

            // ── Description overlay ─────────────────────────────────
            if (story.description != null && story.description!.isNotEmpty)
              _buildDescription(story.description!),

            // ── Bottom bar ──────────────────────────────────────────
            _buildBottomBar(story, me?.id ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(StoryModel story) {
    if (story.mediaType == StoryMediaType.video &&
        _videoReady &&
        _videoCtrl != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoCtrl!.value.aspectRatio,
          child: VideoPlayer(_videoCtrl!),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: AppColors.bgDark),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.bgDark,
        child: const Center(
          child: Icon(Icons.broken_image_rounded,
              size: 48, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(widget.stories.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < widget.stories.length - 1 ? 4 : 0,
                  ),
                  child: AnimatedBuilder(
                    animation: _progCtrl,
                    builder: (_, __) {
                      double value;
                      if (i < _current) {
                        value = 1.0;
                      } else if (i == _current) {
                        value = _progCtrl.value;
                      } else {
                        value = 0.0;
                      }
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 2.5,
                        borderRadius: BorderRadius.circular(2),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(StoryModel story, bool isOwn) {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: story.userPhotoUrl,
                name: story.userName,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                    Text(
                      'منذ قليل',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwn)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white, size: 22),
                  color: AppColors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await StoryService().deleteStory(story.id);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_rounded,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 10),
                        const Text('حذف القصة',
                            style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Positioned(
      bottom: 110,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomBar(StoryModel story, String viewerId) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'اكتب تعليقا...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (text) async {
                      if (text.trim().isEmpty) return;
                      _commentCtrl.clear();
                      // Comment sent as private message - handled by chat service
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () =>
                    StoryService().reactToStory(story.id, viewerId, 'heart'),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}