import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mr7_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  bool _loading = false;
  bool _showPass = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Unfocus keyboard first
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final l = AppLocalizations.of(context);

    try {
      final user = await AuthService().login(
        username: _userCtrl.text.trim().toLowerCase(),
        password: _passCtrl.text.trim(),
      );
      if (!mounted) return;
      context.read<AppProvider>().setUser(user);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on Exception catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      // Map error codes to localized strings
      final Map<String, String> errorMap = {
        'accountNotFound': l['accountNotFound'],
        'wrongPassword': l['wrongPassword'],
        'invalidCredentials': l['invalidCredentials'],
        'accountBanned': 'تم حظر هذا الحساب',
      };
      setState(() {
        _errorMsg = errorMap[msg] ?? l['unknownError'];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final screenH = MediaQuery.of(context).size.height;

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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(children: [
                SizedBox(height: screenH * 0.06),

                // Dragon logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/app_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const MR7Logo(fontSize: 28, animate: false),
                    ),
                  ),
                ),

                
                const SizedBox(height: 32),

                GlassContainer(
                  padding: const EdgeInsets.all(22),
                  borderRadius: BorderRadius.circular(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l['login'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),

                        const SizedBox(height: 18),

                        // Username field
                        _buildField(
                          controller: _userCtrl,
                          label: l['username'],
                          hint: '@username',
                          icon: Icons.alternate_email_rounded,
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? l['usernameRequired'] : null,
                        ),

                        const SizedBox(height: 12),

                        // Password field
                        _buildField(
                          controller: _passCtrl,
                          label: l['password'],
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: !_showPass,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _showPass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? l['passwordRequired'] : null,
                        ),

                        // Error message
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.25)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 14, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                      color: AppColors.accent, fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Login button — compact size
                        SizedBox(
                          height: 42,
                          child: _loading
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    l['login'],
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l['noAccount'],
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 12)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, AppRoutes.register),
                              child: Text(
                                l['registerHere'],
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3)),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 17),
          suffixIcon: suffixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          isDense: true,
        ),
      ),
    ]);
  }
}