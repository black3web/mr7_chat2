import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';

class ChatInputBar extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onClearReply;
  final VoidCallback? onSent;

  const ChatInputBar({
    super.key,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.replyingTo,
    this.onClearReply,
    this.onSent,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _sending = false;
  bool _showAttachMenu = false;
  double _uploadProgress = 0;
  bool _uploading = false;
  late AnimationController _attachCtrl;
  late Animation<double> _attachAnim;

  @override
  void initState() {
    super.initState();
    _attachCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _attachAnim = CurvedAnimation(parent: _attachCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _attachCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _hasText = false; });
    final oldText = text;
    _ctrl.clear();

    try {
      await ChatService().sendMessage(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName,
        senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.text,
        text: oldText,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
      widget.onClearReply?.call();
    } catch (e) {
      if (mounted) {
        _ctrl.text = oldText;
        setState(() => _hasText = true);
        _showError('فشل الإرسال. حاول مجدداً');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage({ImageSource source = ImageSource.gallery}) async {
    _hideAttachMenu();
    XFile? file;
    try {
      file = await StorageService().pickImage(source: source);
    } catch (e) {
      _showError('لا يمكن الوصول إلى الصور');
      return;
    }
    if (file == null || !mounted) return;

    setState(() { _uploading = true; _uploadProgress = 0.1; });
    try {
      // Simulate progress while uploading
      _simulateProgress();
      final url = await StorageService().uploadMedia(file, widget.chatId);
      if (!mounted) return;
      setState(() => _uploadProgress = 0.9);

      await ChatService().sendMessage(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName,
        senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.image,
        mediaUrl: url,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
      widget.onClearReply?.call();
    } catch (e) {
      if (mounted) _showError('فشل رفع الصورة: تحقق من الاتصال');
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; });
    }
  }

  Future<void> _sendVideo() async {
    _hideAttachMenu();
    XFile? file;
    try {
      file = await StorageService().pickVideo();
    } catch (e) {
      _showError('لا يمكن الوصول إلى الفيديو');
      return;
    }
    if (file == null || !mounted) return;

    setState(() { _uploading = true; _uploadProgress = 0.1; });
    try {
      _simulateProgress();
      final url = await StorageService().uploadMedia(file, widget.chatId);
      if (!mounted) return;
      setState(() => _uploadProgress = 0.9);

      await ChatService().sendMessage(
        chatId: widget.chatId,
        senderId: widget.senderId,
        senderName: widget.senderName,
        senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.video,
        mediaUrl: url,
        replyToId: widget.replyingTo?.id,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
      widget.onClearReply?.call();
    } catch (e) {
      if (mounted) _showError('فشل رفع الفيديو: تحقق من الاتصال');
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; });
    }
  }

  void _simulateProgress() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _uploading) {
        setState(() => _uploadProgress = (_uploadProgress + 0.25).clamp(0.0, 0.85));
        if (_uploadProgress < 0.85) _simulateProgress();
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFFCC0022),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _toggleAttachMenu() {
    setState(() => _showAttachMenu = !_showAttachMenu);
    _showAttachMenu ? _attachCtrl.forward() : _attachCtrl.reverse();
    if (_showAttachMenu) _focusNode.unfocus();
  }

  void _hideAttachMenu() {
    if (_showAttachMenu) {
      setState(() => _showAttachMenu = false);
      _attachCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply preview
        if (widget.replyingTo != null)
          _ReplyPreview(
            message: widget.replyingTo!,
            onClose: widget.onClearReply,
          ),

        // Upload progress bar
        if (_uploading)
          _UploadProgressBar(progress: _uploadProgress),

        // Attach menu
        if (_showAttachMenu)
          ScaleTransition(
            scale: _attachAnim,
            alignment: Alignment.bottomCenter,
            child: _AttachMenu(
              onPhoto: () => _sendImage(),
              onCamera: () => _sendImage(source: ImageSource.camera),
              onVideo: _sendVideo,
            ),
          ),

        // Main input row
        ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.bgMedium.withOpacity(0.93),
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(children: [
                // Attach button
                _CircleBtn(
                  icon: _showAttachMenu
                      ? Icons.close_rounded
                      : Icons.attach_file_rounded,
                  color: _showAttachMenu ? AppColors.accent : AppColors.textMuted,
                  onTap: _uploading ? null : _toggleAttachMenu,
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                        onTap: _hideAttachMenu,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send / Mic button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: _hasText
                      ? _SendBtn(key: const ValueKey('send'), loading: _sending, onTap: _send)
                      : _CircleBtn(
                          key: const ValueKey('mic'),
                          icon: Icons.mic_rounded,
                          color: AppColors.textMuted,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرسائل الصوتية قادمة قريباً 🎙️'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          ),
                        ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onClose;
  const _ReplyPreview({required this.message, this.onClose});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.bgMedium,
      border: Border(
        top: BorderSide(color: AppColors.glassBorder),
        left: const BorderSide(color: AppColors.accent, width: 3),
      ),
    ),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            message.senderName ?? 'رسالة',
            style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            message.text ?? (message.type == MessageType.image ? '📷 صورة' : '🎥 فيديو'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
      GestureDetector(
        onTap: onClose,
        child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
      ),
    ]),
  );
}

class _UploadProgressBar extends StatelessWidget {
  final double progress;
  const _UploadProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    color: AppColors.bgMedium,
    child: Column(children: [
      Row(children: [
        const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          'جاري الرفع... ${(progress * 100).toInt()}%',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.bgLight,
          color: AppColors.accent,
          minHeight: 3,
        ),
      ),
    ]),
  );
}

class _AttachMenu extends StatelessWidget {
  final VoidCallback onPhoto, onCamera, onVideo;
  const _AttachMenu({required this.onPhoto, required this.onCamera, required this.onVideo});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: AppColors.bgMedium.withOpacity(0.97),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AttachBtn(icon: Icons.photo_library_rounded, label: 'معرض', color: const Color(0xFF4285F4), onTap: onPhoto),
        _AttachBtn(icon: Icons.camera_alt_rounded, label: 'كاميرا', color: const Color(0xFF00BCD4), onTap: onCamera),
        _AttachBtn(icon: Icons.videocam_rounded, label: 'فيديو', color: const Color(0xFF9C27B0), onTap: onVideo),
      ],
    ),
  );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CircleBtn({super.key, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    ),
  );
}

class _SendBtn extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SendBtn({super.key, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1744), Color(0xFFAA0020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
    ),
  );
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, size: 24, color: color),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
}
