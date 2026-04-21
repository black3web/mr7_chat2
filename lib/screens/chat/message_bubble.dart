import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;                        // FIX: import as ui to avoid TextDirection conflict
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart' hide TextDirection; // FIX: Hide TextDirection to avoid conflict

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final bool showName;
  final bool isSelected;
  final bool selectionMode;
  final Function(MessageModel)? onReply;
  final Function(MessageModel)? onDelete;
  final Function(MessageModel)? onEdit;
  final Function(MessageModel, String)? onReact;
  final Function(MessageModel)? onSelect;
  final Function(MessageModel)? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.showName = false,
    this.isSelected = false,
    this.selectionMode = false,
    this.onReply,
    this.onDelete,
    this.onEdit,
    this.onReact,
    this.onSelect,
    this.onTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _swipeCtrl;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swipeCtrl.dispose();
    super.dispose();
  }

  void _showOptions(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 6),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Reactions row
          Directionality(
            textDirection: TextDirection.ltr,           // FIX: TextDirection from material.dart (no conflict)
            child: SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: AppConstants.reactions.map((e) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReact?.call(widget.message, e);
                  },
                  child: Container(
                    width: 44, height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Actions
          if (widget.message.text != null)
            _action(context, Icons.copy_rounded, l['copy'], () {
              Clipboard.setData(ClipboardData(text: widget.message.text!));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l['messageCopied']),
                duration: const Duration(milliseconds: 1200),
                behavior: SnackBarBehavior.floating,
              ));
            }),
          _action(context, Icons.reply_rounded, l['replyTo'],
              () => widget.onReply?.call(widget.message)),
          _action(context, Icons.select_all_rounded, 'تحديد',
              () => widget.onSelect?.call(widget.message)),
          if (widget.isMine && widget.message.type == MessageType.text)
            _action(context, Icons.edit_rounded, l['editMessage'],
                () => widget.onEdit?.call(widget.message)),
          if (widget.isMine)
            _action(context, Icons.delete_outline_rounded, l['deleteMessage'],
                () => widget.onDelete?.call(widget.message),
                color: AppColors.accent),
          const SizedBox(height: 6),
        ]),
      ),
    );
  }

  Widget _action(BuildContext ctx, IconData icon, String label,
      VoidCallback onPressed, {Color? color}) {
    return InkWell(
      onTap: () { Navigator.pop(ctx); onPressed(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) return _buildDeleted(context);
    if (widget.message.type == MessageType.system) return _buildSystem();
    if (widget.message.isEmojiOnly && widget.message.emojiCount <= 6) {
      return _buildEmoji(context);
    }

    // Swipe-to-reply gesture
    return Directionality(
      textDirection: TextDirection.ltr,                // FIX: explicit — no ambiguity
      child: GestureDetector(
        onHorizontalDragUpdate: widget.selectionMode ? null : (d) {
          setState(() {
            _dragOffset = (_dragOffset + d.delta.dx).clamp(0.0, 60.0);
          });
        },
        onHorizontalDragEnd: widget.selectionMode ? null : (d) {
          if (_dragOffset >= 40) {
            widget.onReply?.call(widget.message);
            HapticFeedback.lightImpact();
          }
          setState(() => _dragOffset = 0);
        },
        child: Stack(
          children: [
            // Reply icon that appears on swipe
            if (_dragOffset > 10)
              Positioned(
                left: widget.isMine ? null : 8,
                right: widget.isMine ? 8 : null,
                top: 0, bottom: 0,
                child: Center(
                  child: Opacity(
                    opacity: (_dragOffset / 40).clamp(0.0, 1.0),
                    child: const Icon(Icons.reply_rounded,
                        size: 20, color: AppColors.accent),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: GestureDetector(
                onTap: widget.selectionMode
                    ? () => widget.onSelect?.call(widget.message)
                    : widget.onTap != null
                        ? () => widget.onTap!(widget.message)
                        : null,
                onLongPress: widget.selectionMode
                    ? null
                    : () => _showOptions(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: widget.isSelected
                      ? AppColors.accent.withOpacity(0.12)
                      : Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 3,
                      left: widget.isMine ? 52 : (widget.selectionMode ? 48 : 0),
                      right: widget.isMine ? (widget.selectionMode ? 48 : 0) : 52,
                    ),
                    child: Row(
                      mainAxisAlignment: widget.isMine
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Selection checkbox — left of others' message
                        if (widget.selectionMode && !widget.isMine) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 4),
                            child: _SelectCircle(selected: widget.isSelected),
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Avatar
                        if (!widget.isMine && widget.showAvatar)
                          Padding(
                            padding: const EdgeInsets.only(right: 6, bottom: 2),
                            child: UserAvatar(
                              photoUrl: widget.message.senderPhotoUrl,
                              name: widget.message.senderName ?? '?',
                              size: 28,
                            ),
                          )
                        else if (!widget.isMine)
                          const SizedBox(width: 36),

                        // Bubble content
                        Flexible(
                          child: Column(
                            crossAxisAlignment: widget.isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!widget.isMine &&
                                  widget.showName &&
                                  widget.message.senderName != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 3, left: 14),
                                  child: Text(
                                    widget.message.senderName!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (widget.message.isForwarded)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 2, left: 14, right: 14),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.forward_rounded,
                                            size: 11,
                                            color: AppColors.textMuted),
                                        const SizedBox(width: 3),
                                        Text(
                                          AppLocalizations.of(context)[
                                              'forwarded'],
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted),
                                        ),
                                      ]),
                                ),
                              _GlassBubble(
                                  message: widget.message,
                                  isMine: widget.isMine),
                              if (widget.message.reactions.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                _ReactionsBar(
                                    reactions: widget.message.reactions),
                              ],
                            ],
                          ),
                        ),

                        if (widget.isMine) const SizedBox(width: 34),

                        // Selection checkbox — right of my messages
                        if (widget.selectionMode && widget.isMine) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4, right: 4),
                            child: _SelectCircle(selected: widget.isSelected),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji(BuildContext context) {
    final size = widget.message.emojiCount <= 1
        ? 46.0
        : widget.message.emojiCount <= 3
            ? 34.0
            : 26.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onLongPress: () => _showOptions(context),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 3,
            left: widget.isMine ? 52 : 0,
            right: widget.isMine ? 0 : 52,
          ),
          child: Row(
            mainAxisAlignment: widget.isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Text(widget.message.text!,
                  style: TextStyle(fontSize: size)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleted(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 3,
          left: widget.isMine ? 52 : 0,
          right: widget.isMine ? 0 : 52,
        ),
        child: Row(
          mainAxisAlignment: widget.isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.not_interested_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  l['messageDeleted'],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystem() => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        widget.message.text ?? '',
        style: TextStyle(
            fontSize: 11, color: Colors.white.withOpacity(0.45)),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ─── Selection circle ──────────────────────────────────────────────────
class _SelectCircle extends StatelessWidget {
  final bool selected;
  const _SelectCircle({required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 22, height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? AppColors.accent : Colors.transparent,
      border: Border.all(
        color: selected ? AppColors.accent : AppColors.textMuted,
        width: 1.5,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
        : null,
  );
}

// ─── Glass Bubble ──────────────────────────────────────────────────────
class _GlassBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  const _GlassBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // FIX: ui.ImageFilter
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.70,
            minWidth: 60,
          ),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: isMine
                  ? [
                      AppColors.primary.withOpacity(0.35),
                      AppColors.primaryDark.withOpacity(0.20),
                    ]
                  : [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isMine
                  ? AppColors.primary.withOpacity(0.55)
                  : Colors.white.withOpacity(0.13),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply quote
              if (message.replyToId != null) ...[
                _ReplyQuote(
                    text: message.replyToText,
                    sender: message.replyToSenderId),
                const SizedBox(height: 6),
              ],
              // Image
              if (message.type == MessageType.image &&
                  message.mediaUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: AppColors.bgLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 80,
                      color: AppColors.bgLight,
                      child: const Icon(Icons.broken_image_rounded,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
                if (message.text != null && message.text!.isNotEmpty)
                  const SizedBox(height: 6),
              ],
              // Text with automatic RTL/LTR detection
              if (message.text != null && message.text!.isNotEmpty)
                Directionality(
                  textDirection: _isArabic(message.text!)
                      ? TextDirection.rtl                 // FIX: TextDirection from material.dart
                      : TextDirection.ltr,
                  child: Text(
                    message.text!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14.5, height: 1.45),
                  ),
                ),
              const SizedBox(height: 3),
              // Time + status row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.isEdited)
                    Text(
                      AppLocalizations.of(context)['messageEdited'],
                      style: TextStyle(
                          fontSize: 9, color: Colors.white.withOpacity(0.4)),
                    ),
                  if (message.isEdited) const SizedBox(width: 3),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                        fontSize: 9, color: Colors.white.withOpacity(0.45)),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    Icon(
                      message.status == MessageStatus.read
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: message.status == MessageStatus.read
                          ? AppColors.read
                          : Colors.white.withOpacity(0.4),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isArabic(String t) => RegExp(r'[\u0600-\u06FF]').hasMatch(t);
}

// ─── Reply Quote ──────────────────────────────────────────────────────
class _ReplyQuote extends StatelessWidget {
  final String? text, sender;
  const _ReplyQuote({this.text, this.sender});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.22),
      borderRadius: BorderRadius.circular(8),
      border: const Border(
          left: BorderSide(color: AppColors.accent, width: 2.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (sender != null)
        Text(sender!,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      Text(
        text ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 12, color: Colors.white.withOpacity(0.6)),
      ),
    ]),
  );
}

// ─── Reactions Bar ────────────────────────────────────────────────────
class _ReactionsBar extends StatelessWidget {
  final Map<String, ReactionModel> reactions;
  const _ReactionsBar({required this.reactions});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: reactions.entries.map((e) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(e.key, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(
          '${e.value.userIds.length}',
          style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary),
        ),
      ]),
    )).toList(),
  );
}
