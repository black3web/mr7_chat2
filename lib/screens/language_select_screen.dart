import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import 'dart:math' as math;

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});
  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen>
    with TickerProviderStateMixin {
  String? _selected;
  bool _loading = false;
  late AnimationController _entryCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
    // Pre-select language if already chosen
    _selected = context.read<AppProvider>().language;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_selected == null || _loading) return;
    setState(() => _loading = true);
    try {
      // ✅ This now works because _notify() calls notifyListeners() properly
      await context.read<AppProvider>().setLanguage(_selected!);
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      debugPrint('[LanguageSelect] $e');
      // Even if saving fails, navigate anyway
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _selected == 'ar';
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Stack(
          children: [
            // Animated background
            Positioned.fill(
              child: CustomPaint(painter: _BgPainter(_bgAnim.value)),
            ),
            child!,
          ],
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(children: [
                  const Spacer(flex: 2),

                  // Logo
                  _AnimatedLogo(loading: _loading),
                  const SizedBox(height: 20),

                  Text(
                    'MR7 Chat',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختر لغتك  /  Select Language',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Language cards
                  _LangCard(
                    flag: '🇮🇶',
                    label: 'العربية',
                    sublabel: 'Arabic',
                    selected: _selected == 'ar',
                    onTap: () => setState(() => _selected = 'ar'),
                  ),
                  const SizedBox(height: 14),
                  _LangCard(
                    flag: '🇬🇧',
                    label: 'English',
                    sublabel: 'الإنجليزية',
                    selected: _selected == 'en',
                    onTap: () => setState(() => _selected = 'en'),
                  ),

                  const Spacer(flex: 3),

                  // Continue button
                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 250),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GestureDetector(
                        onTap: _selected != null && !_loading ? _continue : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            gradient: _selected != null
                                ? const LinearGradient(
                                    colors: [Color(0xFFFF1744), Color(0xFFAA0020)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _selected == null ? AppColors.bgLight : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _selected != null
                                ? [BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isAr ? 'متابعة' : 'Continue',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: _selected != null ? Colors.white : AppColors.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: _selected != null ? Colors.white : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  final bool loading;
  const _AnimatedLogo({required this.loading});
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) => Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(_pulse.value * 0.5),
            blurRadius: 30 + _pulse.value * 15,
            spreadRadius: _pulse.value * 4,
          ),
        ],
      ),
      child: child,
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/icons/app_logo.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.bgCard,
          child: const Center(
            child: Text('MR7', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.accent)),
          ),
        ),
      ),
    ),
  );
}

class _LangCard extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LangCard({
    required this.flag,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.25)
            : AppColors.bgLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.glassBorder,
          width: selected ? 1.8 : 0.8,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(children: [
        Text(flag, style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ]),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected
              ? const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 24, key: ValueKey('on'))
              : Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 24, key: ValueKey('off')),
        ),
      ]),
    ),
  );
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const RadialGradient(
      center: Alignment(0, -0.4),
      radius: 1.4,
      colors: [Color(0xFF1A0008), Color(0xFF060006), Color(0xFF0A0A0A)],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);

    // Animated glow orbs
    final sin1 = math.sin(t * math.pi * 2);
    final cos1 = math.cos(t * math.pi * 2);

    paint.shader = RadialGradient(
      colors: [const Color(0x258B0000), Colors.transparent],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * (0.3 + sin1 * 0.1), size.height * (0.2 + cos1 * 0.08)),
      radius: 180,
    ));
    canvas.drawCircle(
      Offset(size.width * (0.3 + sin1 * 0.1), size.height * (0.2 + cos1 * 0.08)),
      180,
      paint,
    );

    paint.shader = RadialGradient(
      colors: [const Color(0x18FF1744), Colors.transparent],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * (0.7 - sin1 * 0.08), size.height * (0.75 + cos1 * 0.06)),
      radius: 150,
    ));
    canvas.drawCircle(
      Offset(size.width * (0.7 - sin1 * 0.08), size.height * (0.75 + cos1 * 0.06)),
      150,
      paint,
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
