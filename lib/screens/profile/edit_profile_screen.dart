import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _bioCtrl;
  final _passCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  bool _uploadingPhoto = false;
  String? _photoUrl;
  bool _showPass = false;
  bool _showNewPass = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _userCtrl = TextEditingController(text: user.username);
    _bioCtrl = TextEditingController(text: user.bio ?? '');
    _photoUrl = user.photoUrl;
    
    // Track changes
    for (final c in [_nameCtrl, _userCtrl, _bioCtrl, _passCtrl, _newPassCtrl]) {
      c.addListener(() => setState(() => _hasUnsavedChanges = true));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _userCtrl.dispose(); _bioCtrl.dispose();
    _passCtrl.dispose(); _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
          title: const Text('من المعرض', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
          title: const Text('الكاميرا', style: TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        const SizedBox(height: 12),
      ]),
    );
    if (source == null) return;

    final file = await StorageService().pickImage(source: source);
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await StorageService().uploadProfilePhoto(file);
      if (mounted) setState(() { _photoUrl = url; _hasUnsavedChanges = true; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final username = _userCtrl.text.trim().toLowerCase();
    final bio = _bioCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l['nameRequired']), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService().updateProfile(
        name: name,
        username: username,
        bio: bio.isEmpty ? null : bio,
        photoUrl: _photoUrl,
        newPassword: newPass.isNotEmpty ? newPass : null,
      );
      await context.read<AppProvider>().refreshUser();
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l['success']), backgroundColor: AppColors.online, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l[msg] ?? l['unknownError']), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = context.read<AppProvider>().currentUser!;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D0005), Color(0xFF0A0A0A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              Text(l['editProfile'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : TextButton(
                    onPressed: _hasUnsavedChanges ? _save : null,
                    child: Text(l['save'], style: TextStyle(color: _hasUnsavedChanges ? AppColors.accent : AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
            ]),
          ),
          // Body
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Photo
              Stack(alignment: Alignment.center, children: [
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickPhoto,
                  child: _uploadingPhoto
                    ? Container(width: 88, height: 88, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgLight), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
                    : Stack(children: [
                        UserAvatar(photoUrl: _photoUrl, name: user.name, size: 88),
                        Positioned(bottom: 0, right: 0, child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle, border: Border.all(color: AppColors.bgDark, width: 2)),
                          child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                        )),
                      ]),
                ),
              ]),
              const SizedBox(height: 22),

              GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
                _field(ctrl: _nameCtrl, label: l['name'], icon: Icons.person_rounded, maxLength: AppConstants.maxNameLen),
                const SizedBox(height: 12),
                _field(ctrl: _userCtrl, label: l['username'], icon: Icons.alternate_email_rounded, maxLength: AppConstants.maxUsernameLen, prefix: '@'),
                const SizedBox(height: 12),
                _field(ctrl: _bioCtrl, label: 'Bio', icon: Icons.info_outline_rounded, maxLines: 3),
              ])),

              const SizedBox(height: 12),
              GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l['changePassword'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 12),
                _field(ctrl: _passCtrl, label: l['currentPassword'], icon: Icons.lock_outline_rounded, obscure: !_showPass,
                  suffix: IconButton(padding: EdgeInsets.zero, icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted), onPressed: () => setState(() => _showPass = !_showPass))),
                const SizedBox(height: 12),
                _field(ctrl: _newPassCtrl, label: l['newPassword'], icon: Icons.lock_rounded, obscure: !_showNewPass,
                  suffix: IconButton(padding: EdgeInsets.zero, icon: Icon(_showNewPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted), onPressed: () => setState(() => _showNewPass = !_showNewPass))),
              ])),

              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 42, child: ElevatedButton(
                onPressed: (_loading || !_hasUnsavedChanges) ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l['save'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              )),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _field({required TextEditingController ctrl, required String label, required IconData icon, bool obscure = false, int maxLines = 1, int? maxLength, String? prefix, Widget? suffix}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 17), prefixText: prefix, prefixStyle: const TextStyle(color: AppColors.textMuted), suffixIcon: suffix, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
      ),
    ]);
  }
}