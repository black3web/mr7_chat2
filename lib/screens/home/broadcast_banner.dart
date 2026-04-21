import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class BroadcastBanner extends StatefulWidget {
  const BroadcastBanner({super.key});
  @override
  State<BroadcastBanner> createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends State<BroadcastBanner> {
  Map<String, dynamic>? _current;
  bool _visible = false;
  // ✅ FIX: Keep StreamSubscription to properly cancel on dispose (memory leak)
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _sub = AdminService().getBroadcasts().listen((list) {
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() => _visible = false);
        return;
      }
      final userId = context.read<AppProvider>().currentUser?.id ?? '';
      final filtered = list.where((b) {
        final dismissed = b['dismissedBy'] as Map<String, dynamic>? ?? {};
        return !(dismissed[userId] ?? false);
      }).toList();
      if (filtered.isEmpty) {
        setState(() => _visible = false);
        return;
      }
      setState(() {
        _current = filtered.first;
        _visible = true;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel(); // ✅ Properly cancel subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _current == null) return const SizedBox.shrink();
    final msg   = _current!['message'] as String? ?? '';
    final title = _current!['title'] as String? ?? '';
    if (msg.isEmpty && title.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.accentGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.campaign_rounded, size: 18, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            if (msg.isNotEmpty)
              Text(msg,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ]),
        ),
        GestureDetector(
          onTap: () {
            final userId = context.read<AppProvider>().currentUser?.id ?? '';
            AdminService().dismissBroadcast(_current!['id'] as String? ?? '', userId)
                .catchError((_) {});
            setState(() => _visible = false);
          },
          child: Container(
            padding: const EdgeInsets.all(3),
            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
