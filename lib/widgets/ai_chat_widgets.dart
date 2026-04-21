import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'user_avatar.dart';

/// Shared data class for AI chat messages
class AiMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;

  const AiMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });
}

/// Header bar for all AI chat screens
class AiScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<Widget>? actions;

  const AiScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgMedium.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
          ],
        )),
        if (actions != null) ...actions!,
      ]),
    );
  }
}

/// Message bubble for AI chat screens
class AiMessageBubble extends StatelessWidget {
  final AiMessage msg;
  final String? userPhotoUrl;
  final String userName;

  const AiMessageBubble({
    super.key,
    required this.msg,
    this.userPhotoUrl,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: msg.isUser ? 48 : 0,
        right: msg.isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: AppGradients.accentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? AppColors.bubbleSelf
                    : msg.isError
                        ? AppColors.accent.withOpacity(0.15)
                        : AppColors.bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: msg.isUser
                      ? AppColors.bubbleSelfBorder
                      : AppColors.bubbleOtherBorder,
                ),
              ),
              child: SelectableText(
                msg.text,
                style: TextStyle(
                  color: msg.isError ? AppColors.accent : Colors.white,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            UserAvatar(
                photoUrl: userPhotoUrl, name: userName, size: 28),
          ],
        ],
      ),
    );
  }
}

/// Animated typing indicator
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: AppGradients.accentGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bubbleOther,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.bubbleOtherBorder),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctrl.value - i * 0.18).clamp(0.0, 1.0);
                final opacity = 0.3 + 0.7 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                return Container(
                  margin: EdgeInsets.only(left: i > 0 ? 5 : 0),
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(opacity),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Bottom input bar for AI chats
class AiInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool loading;
  final String hint;

  const AiInputBar({
    super.key,
    required this.ctrl,
    required this.onSend,
    required this.loading,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.bgMedium.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TextField(
              controller: ctrl,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: loading ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: loading ? null : AppGradients.accentGradient,
              color: loading ? AppColors.bgLight : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: loading
                  ? null
                  : [BoxShadow(color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.accent),
                  )
                : const Icon(Icons.send_rounded, size: 22, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}