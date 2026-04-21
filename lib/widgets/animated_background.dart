import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _ctrl1, _ctrl2, _ctrl3;
  late Animation<double> _anim1, _anim2, _anim3;

  @override
  void initState() {
    super.initState();
    _ctrl1 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _ctrl2 = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
    _ctrl3 = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _anim1 = CurvedAnimation(parent: _ctrl1, curve: Curves.easeInOut);
    _anim2 = CurvedAnimation(parent: _ctrl2, curve: Curves.easeInOut);
    _anim3 = CurvedAnimation(parent: _ctrl3, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl1.dispose(); _ctrl2.dispose(); _ctrl3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(
        animation: Listenable.merge([_anim1, _anim2, _anim3]),
        builder: (_, __) => CustomPaint(
          painter: _BgPainter(_anim1.value, _anim2.value, _anim3.value),
          child: const SizedBox.expand(),
        ),
      ),
      widget.child,
    ]);
  }
}

class _BgPainter extends CustomPainter {
  final double t1, t2, t3;
  _BgPainter(this.t1, this.t2, this.t3);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark gradient base
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0A0A0A), Color(0xFF0D0005), Color(0xFF0A0A0A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Orb 1 - dark crimson
    _drawOrb(canvas, size,
      cx: size.width * (0.2 + 0.3 * t1),
      cy: size.height * (0.15 + 0.2 * t2),
      r: size.width * 0.35,
      color: const Color(0xFF5C0000).withOpacity(0.25),
    );
    // Orb 2 - deep red
    _drawOrb(canvas, size,
      cx: size.width * (0.7 - 0.2 * t2),
      cy: size.height * (0.6 + 0.15 * t3),
      r: size.width * 0.4,
      color: const Color(0xFF3A0000).withOpacity(0.2),
    );
    // Orb 3 - accent glow
    _drawOrb(canvas, size,
      cx: size.width * (0.5 + 0.2 * t3),
      cy: size.height * (0.35 - 0.1 * t1),
      r: size.width * 0.25,
      color: const Color(0xFF8B0000).withOpacity(0.12),
    );

    // Geometric lines
    _drawGeoLines(canvas, size, t1, t2);
  }

  void _drawOrb(Canvas canvas, Size size, {required double cx, required double cy, required double r, required Color color}) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  void _drawGeoLines(Canvas canvas, Size size, double t1, double t2) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Diagonal grid lines
    final spacing = size.width * 0.15;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x + size.width * 0.05 * t1, 0),
        Offset(x + size.height + size.width * 0.05 * t1, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t1 != t1 || old.t2 != t2 || old.t3 != t3;
}
