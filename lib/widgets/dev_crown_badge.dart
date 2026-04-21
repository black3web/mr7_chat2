import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

/// Animated crown badge for developer account — red crown + star particles + pulse
class DevCrownBadge extends StatefulWidget {
  final double size;
  const DevCrownBadge({super.key, this.size = 18});

  @override
  State<DevCrownBadge> createState() => _DevCrownBadgeState();
}

class _DevCrownBadgeState extends State<DevCrownBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.0,
      height: widget.size * 1.8,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _CrownPainter(
            progress: _ctrl.value,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final double progress;
  final double size;
  _CrownPainter({required this.progress, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    // Glow pulse
    final glowRadius = size * (0.85 + sin(progress * 2 * pi) * 0.12);
    final glowPaint = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.18 + sin(progress * 2 * pi) * 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy + size * 0.05), glowRadius, glowPaint);

    // Crown body
    final crownPath = Path();
    final w = size * 1.4;
    final h = size * 0.9;
    final left = cx - w / 2;
    final top = cy - h / 2;
    final bot = cy + h / 2;

    crownPath.moveTo(left, bot);
    crownPath.lineTo(left, top + h * 0.4);
    crownPath.lineTo(left + w * 0.25, top + h * 0.7);
    crownPath.lineTo(cx, top);
    crownPath.lineTo(left + w * 0.75, top + h * 0.7);
    crownPath.lineTo(left + w, top + h * 0.4);
    crownPath.lineTo(left + w, bot);
    crownPath.close();

    // Crown fill gradient
    final crownPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFFF6B6B), Color(0xFFFF1744), Color(0xFF9B0000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(left, top, w, h));
    canvas.drawPath(crownPath, crownPaint);

    // Crown stroke
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(crownPath, strokePaint);

    // Stars / particles
    final rng = Random(42);
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi + progress * 2 * pi;
      final r = size * (0.9 + rng.nextDouble() * 0.4);
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r * 0.7 - size * 0.15;
      final starOpacity = (0.4 + sin(progress * 2 * pi + i) * 0.6).clamp(0.0, 1.0);
      final starSize = size * (0.06 + sin(progress * 2 * pi + i * 1.2) * 0.04);

      _drawStar(canvas, Offset(px, py), starSize, starOpacity);
    }

    // Crown dots (jewels)
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final dotPositions = [
      Offset(cx, top + 1),
      Offset(left + w * 0.25, top + h * 0.72),
      Offset(left + w * 0.75, top + h * 0.72),
    ];
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, size * 0.06, dotPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, double opacity) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + i * 2 * pi / 5;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      final innerAngle = angle + pi / 5;
      path.lineTo(center.dx + r * 0.4 * cos(innerAngle),
          center.dy + r * 0.4 * sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter old) => old.progress != progress;
}