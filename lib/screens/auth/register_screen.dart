import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mr7_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPass = false, _showConfirm = false;
  String? _errorMsg;
  bool? _userAvailable;
  bool _checkingUser = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String val) async {
    if (val.length < 4 || !RegExp(AppConstants.usernamePattern).hasMatch(val)) {
      setState(() => _userAvailable = null);
      return;
    }
    setState(() => _checkingUser = true);
    final available = await AuthService().isUsernameAvailable(val.toLowerCase());
    if (mounted) setState(() { _userAvailable = available; _checkingUser = false; });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_userAvailable == false) {
      setState(() => _errorMsg = AppLocalizations.of(context)['usernameTaken']);
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    final l = AppLocalizations.of(context);

    try {
      final user = await AuthService().register(
        name: _nameCtrl.text.trim(),
        username: _userCtrl.text.trim().toLowerCase(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      context.read<AppProvider>().setUser(user);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on Exception catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      final errorMap = {
        'usernameTaken': l['usernameTaken'],
        'usernameRequired': l['usernameRequired'],
      };
      setState(() { _errorMsg = errorMap[msg] ?? l['unknownError']; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0005), Color(0xFF0A0A0A), Color(0xFF0D0005)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(children: [
              const SizedBox(height: 16),

              // Dragon logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: 16)
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/app_logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const MR7Logo(fontSize: 22, animate: false),
                  ),
                ),
              ),

              
              const SizedBox(height: 22),

              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(20),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l['register'],
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 16),

                    // Name
                    _buildField(
                      ctrl: _nameCtrl,
                      label: l['name'],
                      hint: l['namePlaceholder'],
                      icon: Icons.person_rounded,
                      maxLength: AppConstants.maxNameLen,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l['nameRequired'];
                        if (v.length > AppConstants.maxNameLen) return l['nameTooLong'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Username
                    _buildField(
                      ctrl: _userCtrl,
                      label: l['username'],
                      hint: l['usernamePlaceholder'],
                      icon: Icons.alternate_email_rounded,
                      maxLength: AppConstants.maxUsernameLen,
                      onChanged: _checkUsername,
                      suffix: _checkingUser
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.accent))
                          : _userAvailable == null
                              ? null
                              : Icon(
                                  _userAvailable!
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _userAvailable!
                                      ? AppColors.online
                                      : AppColors.accent,
                                  size: 18),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l['usernameRequired'];
                        if (v.length < AppConstants.minUsernameLen) return l['usernameTooShort'];
                        if (v.length > AppConstants.maxUsernameLen) return l['usernameTooLong'];
                        if (!RegExp(AppConstants.usernamePattern).hasMatch(v))
                          return l['usernameInvalid'];
                        if (_userAvailable == false) return l['usernameTaken'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Password
                    _buildField(
                      ctrl: _passCtrl,
                      label: l['password'],
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showPass,
                      maxLength: AppConstants.maxPasswordLen,
                      suffix: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 17, color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l['passwordRequired'];
                        if (v.length < AppConstants.minPasswordLen) return l['passwordTooShort'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Confirm password
                    _buildField(
                      ctrl: _confirmCtrl,
                      label: l['confirmPassword'],
                      hint: '••••••••',
                      icon: Icons.lock_rounded,
                      obscure: !_showConfirm,
                      suffix: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 17, color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) return l['passwordsNotMatch'];
                        return null;
                      },
                    ),

                    if (_errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.accent, fontSize: 12))),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Register button — compact
                    SizedBox(
                      height: 42,
                      child: _loading
                          ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5)))
                          : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                              child: Text(l['createAccount'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                    ),

                    const SizedBox(height: 14),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l['haveAccount'],
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(l['loginHere'],
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        validator: validator,
        onChanged: onChanged,
        maxLength: maxLength,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 17),
          suffixIcon: suffix,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ),
    ]);
  }
}