import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConstants.colUsers)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  // Get overall statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final stats = <String, dynamic>{};

    try {
      final usersSnap = await _firestore.collection(AppConstants.colUsers).count().get();
      stats['totalUsers'] = usersSnap.count ?? 0;
    } catch (_) {
      stats['totalUsers'] = 0;
    }

    try {
      final groupsSnap = await _firestore.collection(AppConstants.colGroups).count().get();
      stats['totalGroups'] = groupsSnap.count ?? 0;
    } catch (_) {
      stats['totalGroups'] = 0;
    }

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      final activeSnap = await _firestore
          .collection(AppConstants.colUsers)
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(yesterday))
          .count()
          .get();
      stats['activeUsers'] = activeSnap.count ?? 0;
    } catch (_) {
      stats['activeUsers'] = 0;
    }

    try {
      final aiLogsSnap = await _firestore.collection(AppConstants.colAiLogs).count().get();
      stats['totalAiRequests'] = aiLogsSnap.count ?? 0;
    } catch (_) {
      stats['totalAiRequests'] = 0;
    }

    try {
      final supportSnap = await _firestore.collection(AppConstants.colSupport).count().get();
      stats['totalSupportMessages'] = supportSnap.count ?? 0;
    } catch (_) {
      stats['totalSupportMessages'] = 0;
    }

    // AI service breakdown
    try {
      final aiLogs = await _firestore.collection(AppConstants.colAiLogs).get();
      final breakdown = <String, int>{
        'gemini': 0, 'deepseek': 0, 'imageGen': 0, 'nanoBananaPro': 0, 'videoGen': 0
      };
      for (final doc in aiLogs.docs) {
        final service = doc.data()['service'] as String? ?? '';
        if (breakdown.containsKey(service)) {
          breakdown[service] = (breakdown[service] ?? 0) + 1;
        }
      }
      stats['aiBreakdown'] = breakdown;
    } catch (e) { debugPrint('[Admin] $e'); }

    return stats;
  }

  // Ban/unban user
  Future<void> toggleBanUser(String userId, bool ban) async {
    await _firestore.collection(AppConstants.colUsers).doc(userId).update({
      'isBanned': ban,
    });
  }

  // Send broadcast
  Future<void> sendBroadcast({
    required String title,
    required String message,
    String? link,
    required String senderId,
  }) async {
    await _firestore.collection(AppConstants.colBroadcast).add({
      'title': title,
      'message': message,
      'link': link,
      'senderId': senderId,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isActive': true,
    });
  }

  // Get broadcasts
  Stream<List<Map<String, dynamic>>> getBroadcasts() {
    return _firestore
        .collection(AppConstants.colBroadcast)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // Dismiss broadcast for user
  Future<void> dismissBroadcast(String broadcastId, String userId) async {
    await _firestore.collection(AppConstants.colBroadcast).doc(broadcastId).update({
      'dismissedBy.$userId': true,
    });
  }

  // Get support messages
  Stream<List<Map<String, dynamic>>> getSupportMessages() {
    return _firestore
        .collection(AppConstants.colSupport)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // Reply to support message
  Future<void> replyToSupport({
    required String threadId,
    required String senderId,
    required String message,
    List<String>? imageUrls,
  }) async {
    await _firestore
        .collection(AppConstants.colSupport)
        .doc(threadId)
        .collection('replies')
        .add({
      'senderId': senderId,
      'message': message,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isAdminReply': true,
    });

    await _firestore.collection(AppConstants.colSupport).doc(threadId).update({
      'hasUnreadReply': true,
      'lastReplyAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Send notification to specific user
  Future<void> sendUserNotification({
    required String targetUserId,
    required String title,
    required String message,
    String? link,
  }) async {
    await _firestore.collection(AppConstants.colNotifs).add({
      'targetUserId': targetUserId,
      'title': title,
      'message': message,
      'link': link,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isRead': false,
    });
  }

  // Toggle AI service
  Future<void> toggleAiService(String service, bool enabled) async {
    await _firestore.collection('settings').doc('ai_services').set({
      service: enabled,
    }, SetOptions(merge: true));
  }

  // Get AI service states
  Future<Map<String, bool>> getAiServiceStates() async {
    try {
      final doc = await _firestore.collection('settings').doc('ai_services').get();
      if (!doc.exists) return _defaultServiceStates();
      final data = doc.data() as Map<String, dynamic>;
      return {
        'gemini': data['gemini'] ?? true,
        'deepseek': data['deepseek'] ?? true,
        'imageGen': data['imageGen'] ?? true,
        'nanoBananaPro': data['nanoBananaPro'] ?? true,
        'videoGen': data['videoGen'] ?? true,
      };
    } catch (_) {
      return _defaultServiceStates();
    }
  }

  Map<String, bool> _defaultServiceStates() => {
    'gemini': true,
    'deepseek': true,
    'imageGen': true,
    'nanoBananaPro': true,
    'videoGen': true,
  };

  // Get user details with full info
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final doc = await _firestore.collection(AppConstants.colUsers).doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;

    // Get AI usage count
    final aiLogs = await _firestore
        .collection(AppConstants.colAiLogs)
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    data['aiRequestCount'] = aiLogs.count ?? 0;
    return data;
  }

  // Search users by ID or username
  Future<List<UserModel>> searchUsers(String query) async {
    final results = <UserModel>[];
    final lowerQuery = query.toLowerCase().replaceFirst('@', '');

    // By ID
    if (RegExp(r'^\d+$').hasMatch(query)) {
      try {
        final doc = await _firestore.collection(AppConstants.colUsers).doc(query).get();
        if (doc.exists) results.add(UserModel.fromMap(doc.data()!));
      } catch (e) { debugPrint('[Admin] $e'); }
    }

    // By username
    final snap = await _firestore
        .collection(AppConstants.colUsers)
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(20)
        .get();

    for (final doc in snap.docs) {
      final user = UserModel.fromMap(doc.data());
      if (!results.any((u) => u.id == user.id)) results.add(user);
    }

    return results;
  }
}
