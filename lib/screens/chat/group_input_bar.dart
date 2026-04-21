import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';

class GroupInputBar extends StatefulWidget {
  final String groupId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onSent;

  const GroupInputBar({
    super.key,
    required this.groupId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.replyingTo,
    this.onSent,
  });

  @override
  State<GroupInputBar> createState() => _GroupInputBarState();
}

class _GroupInputBarState extends State<GroupInputBar>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  bool _hasText = false;
  bool _sending = false;
  bool _showAttachMenu = false;
  late AnimationController _attachCtrl;
  late Animation<double> _attachAnim;

  @override
  void initState() {
    super.initState();
    _attachCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _attachAnim = CurvedAnimation(parent: _attachCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() { _ctrl.dispose(); _attachCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; _hasText = false; });
    final old = text;
    _ctrl.clear();
    try {
      await GroupService().sendGroupMessage(
        groupId: widget.groupId,
        senderId: widget.senderId,
        senderName: widget.senderName ?? '',
        senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.text,
        text: old,
        replyToId: widget.replyingTo?.id,
        replyToText: widget.replyingTo?.text,
        replyToSenderId: widget.replyingTo?.senderName,
      );
      widget.onSent?.call();
    } catch (e) {
      if (mounted) {
        _ctrl.text = old;
        setState(() => _hasText = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage({ImageSource source = ImageSource.gallery}) async {
    _hideAttach();
    final file = await StorageService().pickImage(source: source);
    if (file == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final url = await StorageService().uploadMedia(file, widget.groupId);
      if (!mounted) return;
      await GroupService().sendGroupMessage(groupId: widget.groupId, senderId: widget.senderId, senderName: widget.senderName ?? '', senderPhotoUrl: widget.senderPhotoUrl, type: MessageType.image, mediaUrl: url);
      widget.onSent?.call();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصورة'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toggleAttach() {
    setState(() => _showAttachMenu = !_showAttachMenu);
    _showAttachMenu ? _attachCtrl.forward() : _attachCtrl.reverse();
  }

  void _hideAttach() {
    if (_showAttachMenu) { setState(() => _showAttachMenu = false); _attachCtrl.reverse(); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_showAttachMenu) ScaleTransition(
        scale: _attachAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.bgMedium.withOpacity(0.97),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _AttachBtn(icon: Icons.image_rounded, label: l['photo'], color: const Color(0xFF4285F4), onTap: _sendImage),
            _AttachBtn(icon: Icons.camera_alt_rounded, label: 'كاميرا', color: const Color(0xFF00BCD4), onTap: () => _sendImage(source: ImageSource.camera)),
          ]),
        ),
      ),
      ClipRRect(child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
          decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.92), border: Border(top: BorderSide(color: AppColors.glassBorder))),
          child: Row(children: [
            _IconBtn(icon: _showAttachMenu ? Icons.close_rounded : Icons.attach_file_rounded, color: _showAttachMenu ? AppColors.accent : AppColors.textMuted, onTap: _toggleAttach),
            const SizedBox(width: 8),
            Expanded(child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: Container(
                decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.glassBorder)),
                child: TextField(
                  controller: _ctrl,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                  decoration: InputDecoration(hintText: l['typeMessage'], hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), isDense: true),
                ),
              ),
            )),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _hasText
                ? _SendBtn(loading: _sending, onTap: _send)
                : _IconBtn(icon: Icons.mic_rounded, color: AppColors.textMuted, onTap: () {}),
            ),
          ]),
        ),
      )),
    ]);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle, border: Border.all(color: AppColors.glassBorder)), child: Icon(icon, size: 18, color: color)));
}

class _SendBtn extends StatelessWidget {
  final bool loading; final VoidCallback onTap;
  const _SendBtn({required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: loading ? null : onTap, child: Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: 8)]), child: loading ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18, color: Colors.white)));
}

class _AttachBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.35))), child: Icon(icon, size: 22, color: color)),
    const SizedBox(height: 5),
    Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  ]));
}