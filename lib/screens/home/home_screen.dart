import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/mr7_logo.dart';
import '../chat/chats_tab.dart';
import '../chat/groups_tab.dart';
import '../ai/ai_services_tab.dart';
import 'home_drawer.dart';
import 'stories_row.dart';
import 'broadcast_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _chatFilter = 'all';
  late TabController _tabCtrl;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AppProvider>().refreshUser());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    if (p.currentUser == null) return const SizedBox();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: HomeDrawer(scaffoldKey: _scaffoldKey),
      floatingActionButton: _buildFAB(context),
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppGradients.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            _buildTopBar(context, l, p),
            const BroadcastBanner(),
            const StoriesRow(),
            _buildTabBar(l),
            _buildChatFilterBar(l),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  ChatsTab(filter: _chatFilter),
                  const GroupsTab(),
                  const AiServicesTab(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, AppLocalizations l, AppProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(children: [
        // Menu + Avatar
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.glassBase,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.menu_rounded,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
        const Spacer(),
        const MR7Logo(fontSize: 26),
        const Spacer(),
        // Search button
        GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.search),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.glassBase,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.search_rounded,
                size: 20, color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabBar(AppLocalizations l) => Container(
    margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    height: 44,
    decoration: BoxDecoration(
      color: AppColors.bgLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: TabBar(
      controller: _tabCtrl,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: AppGradients.accentGradient,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      padding: const EdgeInsets.all(3),
      tabs: [
        Tab(text: l['chats']),
        Tab(text: l['groups']),
        Tab(text: l['aiServices']),
      ],
    ),
  );

  Widget _buildChatFilterBar(AppLocalizations l) {
    final filters = [
      ('all', l['allChats']),
      ('unread', l['unread']),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: filters.map((f) {
          final selected = _chatFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _chatFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: selected ? AppGradients.accentGradient : null,
                  color: selected ? null : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.glassBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) => AnimatedBuilder(
    animation: _tabCtrl,
    builder: (_, __) {
      if (_tabCtrl.index != 0) return const SizedBox.shrink();
      return FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.search),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
      );
    },
  );
}
