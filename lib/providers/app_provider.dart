import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class AppProvider extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ✅ BUG FIX: was `if (!_disposed) _notify()` → infinite recursion StackOverflow!
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  String _language = 'ar';
  String _theme = 'dark';
  int _accentColorValue = 0xFFFF1744;
  double _fontScale = 1.0;
  bool _isLoading = false;
  List<UserModel> _savedAccounts = [];
  String? _chatBackground;
  Map<String, dynamic> _privacySettings = {};
  bool _initialized = false;

  UserModel? get currentUser => _currentUser;
  String get language => _language;
  String get theme => _theme;
  int get accentColorValue => _accentColorValue;
  double get fontScale => _fontScale;
  bool get isDarkTheme => _theme == 'dark';
  bool get isLoading => _isLoading;
  List<UserModel> get savedAccounts => _savedAccounts;
  String? get chatBackground => _chatBackground;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  Map<String, dynamic> get privacySettings => _privacySettings;
  bool get initialized => _initialized;

  void setLoading(bool val) { _isLoading = val; _notify(); }

  void setUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _language = user.settings['language'] ?? _language;
      _theme = user.settings['theme'] ?? _theme;
      _chatBackground = user.settings['chatBackground'];
      _privacySettings = Map<String, dynamic>.from(user.privacy);
    }
    _notify();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _language = prefs.getString(AppConstants.prefLanguage) ?? 'ar';
      _theme = prefs.getString(AppConstants.prefTheme) ?? 'dark';
      _accentColorValue = prefs.getInt('accentColor') ?? 0xFFFF1744;
      _fontScale = prefs.getDouble('fontScale') ?? 1.0;
      _notify();
      final user = await _authService.loadSession();
      if (user != null) setUser(user);
      _savedAccounts = await _authService.getSavedAccounts();
    } catch (e) {
      debugPrint('[AppProvider.init] $e');
    } finally {
      _initialized = true;
      _notify();
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    _notify(); // notify FIRST before async ops so UI updates immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLanguage, lang);
      if (_currentUser != null) {
        final settings = Map<String, dynamic>.from(_currentUser!.settings);
        settings['language'] = lang;
        await _authService.updateProfile(settings: settings);
      }
    } catch (e) {
      debugPrint('[AppProvider.setLanguage] $e');
    }
  }

  Future<void> setAccentColor(Color c) async {
    _accentColorValue = c.value;
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accentColor', c.value);
    } catch (e) { debugPrint('[AppProvider.setAccentColor] $e'); }
  }

  Future<void> setFontScale(double s) async {
    _fontScale = s.clamp(0.8, 1.4);
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontScale', _fontScale);
    } catch (e) { debugPrint('[AppProvider.setFontScale] $e'); }
  }

  Future<void> setTheme(String t) async {
    _theme = t;
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefTheme, t);
      if (_currentUser != null) {
        final settings = Map<String, dynamic>.from(_currentUser!.settings);
        settings['theme'] = t;
        await _authService.updateProfile(settings: settings);
      }
    } catch (e) { debugPrint('[AppProvider.setTheme] $e'); }
  }

  Future<void> setChatBackground(String? bg) async {
    _chatBackground = bg;
    _notify();
    try {
      if (_currentUser != null) {
        final settings = Map<String, dynamic>.from(_currentUser!.settings);
        settings['chatBackground'] = bg;
        await _authService.updateProfile(settings: settings);
      }
      final prefs = await SharedPreferences.getInstance();
      if (bg != null) {
        await prefs.setString(AppConstants.prefChatBg, bg);
      } else {
        await prefs.remove(AppConstants.prefChatBg);
      }
    } catch (e) { debugPrint('[AppProvider.setChatBackground] $e'); }
  }

  Future<void> updatePrivacy(Map<String, dynamic> privacy) async {
    _privacySettings = privacy;
    _notify();
    try {
      await _authService.updateProfile(privacy: privacy);
    } catch (e) { debugPrint('[AppProvider.updatePrivacy] $e'); }
  }

  Future<void> logout() async {
    try { await _authService.logout(); } catch (e) { debugPrint('[AppProvider.logout] $e'); }
    _currentUser = null;
    try { _savedAccounts = await _authService.getSavedAccounts(); } catch (_) {}
    _notify();
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    try {
      final user = await _authService.getUserById(_currentUser!.id);
      if (user != null) setUser(user);
    } catch (e) { debugPrint('[AppProvider.refreshUser] $e'); }
  }

  Future<void> refreshSavedAccounts() async {
    try {
      _savedAccounts = await _authService.getSavedAccounts();
      _notify();
    } catch (e) { debugPrint('[AppProvider.refreshSavedAccounts] $e'); }
  }

  Future<void> switchAccount(String userId) async {
    try {
      final user = await _authService.switchAccount(userId);
      if (user != null) {
        setUser(user);
        _savedAccounts = await _authService.getSavedAccounts();
        _notify();
      }
    } catch (e) { debugPrint('[AppProvider.switchAccount] $e'); }
  }

  Locale get locale => Locale(_language);

  ThemeMode get themeMode {
    switch (_theme) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}
