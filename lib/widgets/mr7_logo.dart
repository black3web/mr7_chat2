import 'package:flutter/material.dart';
import '../config/theme.dart';

class MR7Logo extends StatefulWidget {
  final double fontSize;
  final bool animate;
  final bool showGlow;
  final bool imageMode;

  const MR7Logo({
    super.key,
    this.fontSize = 32,
    this.animate = true,
    this.showGlow = true,
    this.imageMode = false,
  });

  @override
  State<MR7Logo> createState() => _MR7LogoState();
}

class _MR7LogoState extends State<MR7Logo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulse = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animate) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // imageMode: show the dragon image logo
    if (widget.imageMode) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(_pulse.value * 0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/app_logo.jpg',
            width: widget.fontSize * 2.5,
            height: widget.fontSize * 2.5,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildTextLogo(1.0),
          ),
        ),
      );
    }

    if (!widget.animate) return _buildTextLogoWrapped(1.0);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => _buildTextLogoWrapped(_pulse.value),
    );
  }

  // CRITICAL FIX: Wrap in LTR Directionality so RTL app doesn't reverse "MR7" to "7RM"
  Widget _buildTextLogoWrapped(double glowOpacity) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _buildTextLogo(glowOpacity),
    );
  }

  Widget _buildTextLogo(double glowOpacity) {
    final fs = widget.fontSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        // M — white neon
        _NeonLetter(
          letter: 'M',
          fontSize: fs,
          color: Colors.white,
          glowColor: Colors.white,
          glowOpacity: widget.showGlow ? glowOpacity : 0,
        ),
        // R — red neon
        _NeonLetter(
          letter: 'R',
          fontSize: fs,
          color: AppColors.accent,
          glowColor: AppColors.accent,
          glowOpacity: widget.showGlow ? glowOpacity * 0.9 : 0,
        ),
        // 7 — small superscript
        Padding(
          padding: EdgeInsets.only(top: fs * 0.06),
          child: _NeonLetter(
            letter: '7',
            fontSize: fs * 0.42,
            color: const Color(0xFFFF4466),
            glowColor: const Color(0xFFFF4466),
            glowOpacity: widget.showGlow ? glowOpacity * 0.7 : 0,
          ),
        ),
      ],
    );
  }
}

class _NeonLetter extends StatelessWidget {
  final String letter;
  final double fontSize;
  final Color color;
  final Color glowColor;
  final double glowOpacity;

  const _NeonLetter({
    required this.letter,
    required this.fontSize,
    required this.color,
    required this.glowColor,
    required this.glowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: color,
        letterSpacing: -0.5,
        shadows: glowOpacity > 0
            ? [
                Shadow(
                  color: glowColor.withOpacity(glowOpacity * 0.9),
                  blurRadius: fontSize * 0.18,
                ),
                Shadow(
                  color: glowColor.withOpacity(glowOpacity * 0.5),
                  blurRadius: fontSize * 0.36,
                ),
                Shadow(
                  color: glowColor.withOpacity(glowOpacity * 0.22),
                  blurRadius: fontSize * 0.65,
                ),
              ]
            : null,
      ),
    );
  }
}