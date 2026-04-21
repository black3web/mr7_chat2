import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../config/theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 0.8,
    this.blur = 12,
    this.backgroundColor,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(16);
    final bg = backgroundColor ?? (isDark ? AppColors.glassBase : Colors.white.withOpacity(0.7));
    final bc = borderColor ?? (isDark ? AppColors.glassBorder : Colors.white.withOpacity(0.4));

    Widget container = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: br,
            border: Border.all(color: bc, width: borderWidth),
            boxShadow: shadows ?? (isDark ? [
              BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 20, spreadRadius: -2),
            ] : [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12),
            ]),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(margin: margin, child: container),
      );
    }
    return Container(margin: margin, child: container);
  }
}
