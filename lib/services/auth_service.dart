import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Lazy initialization prevents "used before Firebase.initializeApp()"
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;

  // ─── Password hashing ────────────────────────────────────────────
  String _hash(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  // ─── Generate unique 15-digit numeric ID ────────────────────────
  String _generateId() {
    final rng = Random.secure();
    return List.generate(AppConstants.userIdLength, (_) => rng.nextInt(10)).join();
  }

  // ─── Check username availability ─────────────────────────────────
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final snap = await _db
          .collection(AppConstants.colUsers)
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      return snap.docs.isEmpty;
    } catch (e) {
      debugPrint('[Auth] isUsernameAvailable error: $e');
      return false; // Fail safe — don't allow potential duplicates
    }
  }

  // ─── Register ───────────────────────────────────────────────────
  Future<UserModel> register({
    required String name,
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPassword = password.trim();

    // Validate inputs
    if (cleanName.isEmpty) throw Exception('nameRequired');
    if (cleanUsername.length < AppConstants.minUsernameLen) throw Exception('usernameTooShort');
    if (cleanUsername.length > AppConstants.maxUsernameLen) throw Exception('usernameTooLong');
    if (!RegExp(AppConstants.usernamePattern).hasMatch(cleanUsername)) throw Exception('usernameInvalid');
    if (cleanPassword.length < AppConstants.minPasswordLen) throw Exception('passwordTooShort');

    // Check username uniqueness
    final available = await isUsernameAvailable(cleanUsername);
    if (!available) throw Exception('usernameTaken');

    // Generate unique ID
    String userId = _generateId();
    for (int attempt = 0; attempt < 5; attempt++) {
      try {
        final exists = await _db
            .collection(AppConstants.colUsers)
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 8));
        if (!exists.exists) break;
        userId = _generateId();
      } catch (e) {
        break; // Use current ID if check fails
      }
    }

    final now = DateTime.now();
    final user = UserModel(
      id: userId,
      username: cleanUsername,
      name: cleanName,
      passwordHash: _hash(cleanPassword),
      createdAt: now,
      lastSeen: now,
      isOnline: true,
    );

    try {
      await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .set(user.toMap())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('[Auth] Register write error: $e');
      throw Exception('connectionError');
    }

    _currentUser = user;
    await _saveSession(user);
    return user;
  }

  // ─── Login ──────────────────────────────────────────────────────
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty) throw Exception('usernameRequired');
    if (cleanPassword.isEmpty) throw Exception('passwordRequired');

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _db
          .collection(AppConstants.colUsers)
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('[Auth] Login query error: $e');
      throw Exception('connectionError');
    }

    if (snap.docs.isEmpty) throw Exception('accountNotFound');

    UserModel user;
    try {
      user = UserModel.fromMap(snap.docs.first.data());
    } catch (e) {
      debugPrint('[Auth] User parse error: $e');
      throw Exception('unknownError');
    }

    if (user.isBanned) throw Exception('accountBanned');

    if (user.passwordHash != _hash(cleanPassword)) {
      throw Exception('wrongPassword');
    }

    // Update online status (non-blocking, best-effort)
    _db.collection(AppConstants.colUsers).doc(user.id).update({
      'isOnline': true,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    }).catchError((e) => debugPrint('[Auth] Status update: $e'));

    _currentUser = user.copyWith(isOnline: true);
    await _saveSession(user);
    return _currentUser!;
  }

  // ─── Initialize developer account ───────────────────────────────
  Future<void> initDevAccount() async {
    try {
      final snap = await _db
          .collection(AppConstants.colUsers)
          .where('username', isEqualTo: AppConstants.devUsername.toLowerCase())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snap.docs.isEmpty) {
        final dev = UserModel(
          id: AppConstants.devId,
          username: AppConstants.devUsername.toLowerCase(),
          name: AppConstants.devName,
          passwordHash: _hash(AppConstants.devPasswordRaw),
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isAdmin: true,
        );
        await _db
            .collection(AppConstants.colUsers)
            .doc(AppConstants.devId)
            .set(dev.toMap())
            .timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint('[Auth] initDevAccount: $e');
      // Non-critical — app works without dev account
    }
  }

  // ─── Session management ──────────────────────────────────────────
  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefCurrentUser, user.id);
      final accounts = prefs.getStringList(AppConstants.prefAccounts) ?? [];
      if (!accounts.contains(user.id)) {
        accounts.add(user.id);
        await prefs.setStringList(AppConstants.prefAccounts, accounts);
      }
    } catch (e) {
      debugPrint('[Auth] _saveSession: $e');
    }
  }

  Future<UserModel?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.prefCurrentUser);
      if (userId == null || userId.isEmpty) return null;

      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists || doc.data() == null) return null;

      _currentUser = UserModel.fromMap(doc.data()!);
      return _currentUser;
    } catch (e) {
      debugPrint('[Auth] loadSession: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        await _db
            .collection(AppConstants.colUsers)
            .doc(_currentUser!.id)
            .update({
          'isOnline': false,
          'lastSeen': Timestamp.fromDate(DateTime.now()),
        }).timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('[Auth] logout update: $e');
    } finally {
      try {
        final prefs = await SharedPreferences.getInstance();
        final accounts = prefs.getStringList(AppConstants.prefAccounts) ?? [];
        accounts.remove(_currentUser?.id);
        await prefs.setStringList(AppConstants.prefAccounts, accounts);
        await prefs.remove(AppConstants.prefCurrentUser);
      } catch (e) {
        debugPrint('[Auth] logout prefs: $e');
      }
      _currentUser = null;
    }
  }

  Future<UserModel?> switchAccount(String userId) async {
    try {
      if (_currentUser != null) {
        _db.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
          'isOnline': false,
          'lastSeen': Timestamp.fromDate(DateTime.now()),
        }).catchError((e) => debugPrint('[Auth] switch offline: $e'));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefCurrentUser, userId);

      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) return null;
      _currentUser = UserModel.fromMap(doc.data()!);

      _db.collection(AppConstants.colUsers).doc(userId).update({
        'isOnline': true,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      }).catchError((e) => debugPrint('[Auth] switch online: $e'));

      return _currentUser;
    } catch (e) {
      debugPrint('[Auth] switchAccount: $e');
      return null;
    }
  }

  Future<List<UserModel>> getSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(AppConstants.prefAccounts) ?? [];
      final users = <UserModel>[];
      for (final id in ids) {
        try {
          final doc = await _db
              .collection(AppConstants.colUsers)
              .doc(id)
              .get()
              .timeout(const Duration(seconds: 6));
          if (doc.exists && doc.data() != null) {
            users.add(UserModel.fromMap(doc.data()!));
          }
        } catch (e) {
          debugPrint('[Auth] getSavedAccount $id: $e');
        }
      }
      return users;
    } catch (e) {
      debugPrint('[Auth] getSavedAccounts: $e');
      return [];
    }
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? photoUrl,
    String? bio,
    String? newPassword,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentUser == null) return;
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
    if (username != null && username.trim().isNotEmpty) updates['username'] = username.trim().toLowerCase();
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (bio != null) updates['bio'] = bio.trim();
    if (newPassword != null && newPassword.trim().isNotEmpty) updates['passwordHash'] = _hash(newPassword.trim());
    if (privacy != null) updates['privacy'] = privacy;
    if (settings != null) updates['settings'] = settings;

    if (updates.isEmpty) return;

    try {
      await _db
          .collection(AppConstants.colUsers)
          .doc(_currentUser!.id)
          .update(updates)
          .timeout(const Duration(seconds: 10));

      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(_currentUser!.id)
          .get()
          .timeout(const Duration(seconds: 8));

      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('[Auth] updateProfile: $e');
      throw Exception('connectionError');
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;
    _db.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    }).catchError((e) => debugPrint('[Auth] onlineStatus: $e'));
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 8));
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[Auth] getUserById: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final snap = await _db
          .collection(AppConstants.colUsers)
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      if (snap.docs.isEmpty) return null;
      return UserModel.fromMap(snap.docs.first.data());
    } catch (e) {
      debugPrint('[Auth] getUserByUsername: $e');
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final results = <UserModel>[];
    final q = query.trim().toLowerCase().replaceFirst('@', '');
    if (q.isEmpty) return results;

    try {
      final byUsername = await _db
          .collection(AppConstants.colUsers)
          .where('username', isGreaterThanOrEqualTo: q)
          .where('username', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(15)
          .get()
          .timeout(const Duration(seconds: 8));

      for (final doc in byUsername.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.id != _currentUser?.id) results.add(user);
      }

      final byName = await _db
          .collection(AppConstants.colUsers)
          .where('name', isGreaterThanOrEqualTo: query.trim())
          .where('name', isLessThanOrEqualTo: '${query.trim()}\uf8ff')
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 8));

      for (final doc in byName.docs) {
        final user = UserModel.fromMap(doc.data());
        if (user.id != _currentUser?.id &&
            !results.any((u) => u.id == user.id)) {
          results.add(user);
        }
      }
    } catch (e) {
      debugPrint('[Auth] searchUsers: $e');
    }
    return results;
  }

  Future<void> toggleContact(String targetUserId, {String? nickname}) async {
    if (_currentUser == null) return;
    final contacts = List<String>.from(_currentUser!.contacts);
    final nicknames = Map<String, String>.from(_currentUser!.contactNicknames);

    if (contacts.contains(targetUserId)) {
      contacts.remove(targetUserId);
      nicknames.remove(targetUserId);
    } else {
      contacts.add(targetUserId);
      if (nickname != null && nickname.isNotEmpty) nicknames[targetUserId] = nickname;
    }

    try {
      await _db.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
        'contacts': contacts,
        'contactNicknames': nicknames,
      }).timeout(const Duration(seconds: 8));
      _currentUser = _currentUser!.copyWith(contacts: contacts, contactNicknames: nicknames);
    } catch (e) {
      debugPrint('[Auth] toggleContact: $e');
      throw Exception('connectionError');
    }
  }

  Future<void> toggleBlock(String targetUserId) async {
    if (_currentUser == null) return;
    final blocked = List<String>.from(_currentUser!.blocked);
    if (blocked.contains(targetUserId)) {
      blocked.remove(targetUserId);
    } else {
      blocked.add(targetUserId);
    }
    try {
      await _db.collection(AppConstants.colUsers).doc(_currentUser!.id).update({
        'blocked': blocked,
      }).timeout(const Duration(seconds: 8));
      _currentUser = _currentUser!.copyWith(blocked: blocked);
    } catch (e) {
      debugPrint('[Auth] toggleBlock: $e');
      throw Exception('connectionError');
    }
  }

  Stream<UserModel> listenToCurrentUser() {
    if (_currentUser == null) throw Exception('No user logged in');
    return _db
        .collection(AppConstants.colUsers)
        .doc(_currentUser!.id)
        .snapshots()
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) {
      _currentUser = UserModel.fromMap(doc.data()!);
      return _currentUser!;
    });
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    try {
      await _db
          .collection(AppConstants.colUsers)
          .doc(_currentUser!.id)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Auth] deleteAccount: $e');
    } finally {
      await logout();
    }
  }
}