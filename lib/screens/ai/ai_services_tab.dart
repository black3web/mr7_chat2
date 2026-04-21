import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glass_container.dart';

class AiServicesTab extends StatelessWidget {
  const AiServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final services = [
      _Service(
        icon: Icons.chat_bubble_rounded,
        bg: const [Color(0xFF1A237E), Color(0xFF283593)],
        glow: const Color(0xFF3949AB),
        title: 'Gemini 2.5 Flash',
        subtitle: l['geminiChat'],
        route: AppRoutes.geminiChat,
        badge: 'Google',
      ),
      _Service(
        icon: Icons.psychology_rounded,
        bg: const [Color(0xFF006064), Color(0xFF00838F)],
        glow: const Color(0xFF00BCD4),
        title: 'DeepSeek AI',
        subtitle: l['deepSeekChat'],
        route: AppRoutes.deepSeekChat,
        badge: 'V3.2 • R1 • Coder',
      ),
      _Service(
        icon: Icons.image_rounded,
        bg: const [Color(0xFF880E4F), Color(0xFFC2185B)],
        glow: const Color(0xFFE91E63),
        title: 'Nano Banana 2',
        subtitle: l['imageGeneration'],
        route: AppRoutes.imageGen,
        badge: '2K',
      ),
      _Service(
        icon: Icons.auto_fix_high_rounded,
        bg: const [Color(0xFFE65100), Color(0xFFF57C00)],
        glow: const Color(0xFFFF9800),
        title: 'NanoBanana Pro',
        subtitle: l['imageEditing'],
        route: AppRoutes.imageGenPro,
        badge: '4K',
      ),
      _Service(
        icon: Icons.videocam_rounded,
        bg: const [Color(0xFF4A148C), Color(0xFF6A1B9A)],
        glow: const Color(0xFF9C27B0),
        title: 'Seedance AI',
        subtitle: l['videoGeneration'],
        route: AppRoutes.videoGen,
        badge: '1.5 Pro',
      ),
      _Service(
        icon: Icons.play_circle_filled_rounded,
        bg: const [Color(0xFF1565C0), Color(0xFF1976D2)],
        glow: const Color(0xFF2196F3),
        title: 'Video AI',
        subtitle: 'توليد فيديو بالذكاء',
        route: AppRoutes.kilwaVideo,
        badge: 'Fast',
      ),
      _Service(
        icon: Icons.music_note_rounded,
        bg: const [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
        glow: const Color(0xFFAB47BC),
        title: 'AI Music',
        subtitle: 'توليد موسيقى',
        route: AppRoutes.musicAi,
        badge: 'Visco AI',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, i) => _ServiceCard(service: services[i]),
    );
  }
}

class _Service {
  final IconData icon;
  final List<Color> bg;
  final Color glow;
  final String title, subtitle, route, badge;
  const _Service({
    required this.icon,
    required this.bg,
    required this.glow,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.badge,
  });
}

class _ServiceCard extends StatefulWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.pushNamed(context, s.route);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                LinearGradient(colors: s.bg, begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: s.glow.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, size: 22, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s.badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4)),
                ),
              ]),
              const Spacer(),
              Text(s.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2)),
              const SizedBox(height: 3),
              Text(s.subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}