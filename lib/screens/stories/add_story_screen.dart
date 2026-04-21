import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../services/story_service.dart';
import '../../services/storage_service.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});
  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  bool _loading = false;

  Future<void> _pick(ImageSource source, {bool isVideo = false}) async {
    final file = isVideo
        ? await StorageService().pickVideo(source: source)
        : await StorageService().pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final userId = context.read<AppProvider>().currentUser!.id;
      final url = await StorageService().uploadStoryMedia(file, userId);
      if (!mounted) return;

      // Show caption dialog
      final caption = await _showCaptionDialog();
      if (!mounted) return;

      await StoryService().createStory(
        userId: userId,
        userName: context.read<AppProvider>().currentUser!.name,
        userPhotoUrl: context.read<AppProvider>().currentUser!.photoUrl,
        mediaUrl: url,
        mediaType: isVideo ? 'video' : 'image',
        description: caption,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع القصة: $e'),
              backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showCaptionDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('أضف وصفاً (اختياري)'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'اكتب وصفاً لقصتك...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تخطي')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.4,
              colors: [Color(0x401A0008), Color(0xFF0A0A0A)],
            ),
          ),
        ),

        if (_loading)
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: 16),
                  Text('جاري رفع القصة...', style: TextStyle(color: Colors.white, fontSize: 14)),
                ]),
              ),
            ),
          )
        else
          SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('قصة جديدة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
              ),

              Expanded(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 24, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text('اختر نوع القصة',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('قصتك ستظهر لمدة 48 ساعة',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    const SizedBox(height: 36),

                    // Options grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StoryOptionCard(
                          icon: Icons.camera_alt_rounded,
                          label: 'الكاميرا',
                          sublabel: 'التقط صورة',
                          color: const Color(0xFF00BCD4),
                          onTap: () => _pick(ImageSource.camera),
                        ),
                        _StoryOptionCard(
                          icon: Icons.photo_library_rounded,
                          label: 'المعرض',
                          sublabel: 'اختر صورة',
                          color: const Color(0xFF4285F4),
                          onTap: () => _pick(ImageSource.gallery),
                        ),
                        _StoryOptionCard(
                          icon: Icons.videocam_rounded,
                          label: 'فيديو - كاميرا',
                          sublabel: 'سجل فيديو',
                          color: const Color(0xFFE91E63),
                          onTap: () => _pick(ImageSource.camera, isVideo: true),
                        ),
                        _StoryOptionCard(
                          icon: Icons.video_library_rounded,
                          label: 'فيديو - معرض',
                          sublabel: 'اختر فيديو',
                          color: const Color(0xFF9C27B0),
                          onTap: () => _pick(ImageSource.gallery, isVideo: true),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ]),
          ),
      ]),
    );
  }
}

class _StoryOptionCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  final VoidCallback onTap;
  const _StoryOptionCard({required this.icon, required this.label, required this.sublabel,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sublabel, style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ]),
      ),
    ),
  );
}