import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/animated_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<UserModel> _users = [];
  List<GroupModel> _groups = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _users = []; _groups = []; _searched = false; });
      return;
    }
    setState(() { _loading = true; _searched = true; });
    final query = q.trim().replaceFirst('@', '');
    final futures = await Future.wait([
      AuthService().searchUsers(query),
      GroupService().searchGroups(query),
    ]);
    if (mounted) {
      setState(() {
        _users  = futures[0] as List<UserModel>;
        _groups = futures[1] as List<GroupModel>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            // Search bar header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgMedium.withOpacity(0.95),
                border: Border(
                    bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          onChanged: (v) {
                            if (v.isEmpty) {
                              setState(() {
                                _users = [];
                                _groups = [];
                                _searched = false;
                              });
                            } else {
                              _search(v); // Real-time search
                            }
                          },
                          onSubmitted: _search,
                          decoration: InputDecoration(
                            hintText: l['search'],
                            hintStyle: const TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_ctrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _ctrl.clear();
                            setState(() {
                              _users = [];
                              _groups = [];
                              _searched = false;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                          ),
                        ),
                    ]),
                  ),
                ),
              ]),
            ),

            // Results
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : !_searched
                      ? _buildPrompt()
                      : _users.isEmpty && _groups.isEmpty
                          ? _buildNoResults(l)
                          : _buildResults(l),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPrompt() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgLight,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(Icons.search_rounded,
            size: 36, color: AppColors.textMuted.withOpacity(0.5)),
      ),
      const SizedBox(height: 16),
      const Text('ابحث عن أشخاص أو مجموعات',
          style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
      const SizedBox(height: 6),
      Text('ابدأ الكتابة للبحث',
          style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.6), fontSize: 13)),
    ]),
  );

  Widget _buildNoResults(AppLocalizations l) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded,
          size: 56, color: AppColors.textMuted.withOpacity(0.3)),
      const SizedBox(height: 12),
      Text(l['noResults'],
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
    ]),
  );

  Widget _buildResults(AppLocalizations l) => ListView(
    padding: const EdgeInsets.only(bottom: 20),
    children: [
      if (_users.isNotEmpty) ...[
        _SectionHeader(title: l['chats']),
        ..._users.map((u) => _UserTile(user: u)),
      ],
      if (_groups.isNotEmpty) ...[
        _SectionHeader(title: l['groups']),
        ..._groups.map((g) => _GroupTile(group: g, l: l)),
      ],
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: UserAvatar(
      photoUrl: user.photoUrl,
      name: user.name,
      size: 46,
      showOnline: true,
      isOnline: user.isOnline,
    ),
    title: Text(user.name,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700)),
    subtitle: Text('@${user.username}',
        style: const TextStyle(
            color: AppColors.textMuted, fontSize: 12)),
    trailing: user.isOnline
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.online.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.online.withOpacity(0.4)),
            ),
            child: const Text('متصل',
                style: TextStyle(
                    color: AppColors.online,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          )
        : null,
    onTap: () => Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: {'userId': user.id},
    ),
  );
}

class _GroupTile extends StatelessWidget {
  final GroupModel group;
  final AppLocalizations l;
  const _GroupTile({required this.group, required this.l});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: UserAvatar(
      photoUrl: group.photoUrl,
      name: group.name,
      size: 46,
    ),
    title: Text(group.name,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700)),
    subtitle: Text(
      '@${group.username} · ${group.members.length} ${l['members']}',
      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: const Text('مجموعة',
          style: TextStyle(
              color: AppColors.accentLight,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    ),
    onTap: () => Navigator.pushNamed(
      context,
      AppRoutes.groupChat,
      arguments: {'groupId': group.id},
    ),
  );
}
