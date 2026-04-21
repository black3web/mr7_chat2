import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import 'dev_crown_badge.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final bool showOnline;   // FIX: renamed from showOnlineStatus to match all callers
  final bool isOnline;
  final bool isAdmin;
  final bool showCrown;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.size = 44,
    this.showOnline = false,   // FIX: was showOnlineStatus
    this.isOnline = false,
    this.isAdmin = false,
    this.showCrown = false,
    this.onTap,
  });

  Color _avatarColor() {
    if (name.isEmpty) return AppColors.primary;
    final idx = name.codeUnitAt(0) % AppConstants.avatarColors.length;
    return Color(AppConstants.avatarColors[idx]);
  }

  String _initials() {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        // Main circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isAdmin
                ? Border.all(color: AppColors.accent.withOpacity(0.6), width: 1.5)
                : null,
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _InitialsAvatar(
                      initials: _initials(),
                      color: _avatarColor(),
                      size: size,
                    ),
                    errorWidget: (_, __, ___) => _InitialsAvatar(
                      initials: _initials(),
                      color: _avatarColor(),
                      size: size,
                    ),
                  )
                : _InitialsAvatar(
                    initials: _initials(),
                    color: _avatarColor(),
                    size: size,
                  ),
          ),
        ),

        // Online indicator  (FIX: uses showOnline now)
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.27,
              height: size * 0.27,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgDark, width: 1.5),
              ),
            ),
          ),

        // Crown badge for admins / developers
        if (showCrown || isAdmin)
          Positioned(
            top: -size * 0.22,
            left: size * 0.15,
            child: DevCrownBadge(size: size * 0.30),
          ),
      ]),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _InitialsAvatar({
    required this.initials,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    width: size,
    height: size,
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.35,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
