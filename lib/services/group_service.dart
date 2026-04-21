import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../config/constants.dart';

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Check if group username is available
  Future<bool> isGroupUsernameAvailable(String username) async {
    final query = await _firestore
        .collection(AppConstants.colGroups)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Create group
  Future<GroupModel> createGroup({
    required String name,
    required String username,
    required String creatorId,
    String? photoUrl,
    String? description,
  }) async {
    if (!await isGroupUsernameAvailable(username)) {
      throw Exception('اسم المستخدم للمجموعة مستخدم بالفعل');
    }

    final groupId = _uuid.v4();
    final now = DateTime.now();

    final owner = GroupMember(
      userId: creatorId,
      role: 'owner',
      adminPermissions: AdminPermissions.all(),
      joinedAt: now,
    );

    final group = GroupModel(
      id: groupId,
      username: username.toLowerCase(),
      name: name,
      photoUrl: photoUrl,
      description: description,
      ownerId: creatorId,
      members: [owner],
      createdAt: now,
    );

    await _firestore.collection(AppConstants.colGroups).doc(groupId).set(group.toMap());

    // Send welcome system message
    await sendSystemMessage(groupId, 'تم إنشاء المجموعة');

    return group;
  }

  // Send system message
  Future<void> sendSystemMessage(String groupId, String text) async {
    final msgId = _uuid.v4();
    final msg = MessageModel(
      id: msgId,
      chatId: groupId,
      senderId: 'system',
      type: MessageType.system,
      text: text,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .doc(msgId)
        .set(msg.toMap());
  }

  // Join group by username
  Future<GroupModel?> joinGroupByUsername(String username, String userId) async {
    final query = await _firestore
        .collection(AppConstants.colGroups)
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final group = GroupModel.fromMap(query.docs.first.data());

    if (group.memberIds.contains(userId)) return group;
    if (group.getMember(userId)?.isBanned ?? false) throw Exception('أنت محظور من هذه المجموعة');

    final newMember = GroupMember(
      userId: userId,
      role: 'member',
      joinedAt: DateTime.now(),
    );

    final updatedMembers = [...group.members.map((m) => m.toMap()), newMember.toMap()];
    await _firestore.collection(AppConstants.colGroups).doc(group.id).update({
      'members': updatedMembers,
    });

    await sendSystemMessage(group.id, 'انضم عضو جديد');
    return GroupModel.fromMap({...group.toMap(), 'members': updatedMembers});
  }

  // Send message to group
  Future<MessageModel> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String? senderPhotoUrl,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    String? replyToId,
    String? replyToText,
    String? replyToSenderId,
    bool isForwarded = false,
  }) async {
    final msgId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgId,
      chatId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      isForwarded: isForwarded,
      createdAt: now,
    );

    await _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .doc(msgId)
        .set(message.toMap());

    String? displayText = _getDisplayText(type, text, fileName);
    await _firestore.collection(AppConstants.colGroups).doc(groupId).update({
      'lastMessageText': displayText,
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(now),
    });

    return message;
  }

  String? _getDisplayText(MessageType type, String? text, String? fileName) {
    switch (type) {
      case MessageType.text: return text;
      case MessageType.image: return 'صورة';
      case MessageType.video: return 'فيديو';
      case MessageType.file: return fileName ?? 'ملف';
      case MessageType.voice: return 'رسالة صوتية';
      case MessageType.sticker: return 'ملصق';
      case MessageType.emoji: return text;
      case MessageType.system: return text;
    }
  }

  // Listen to group messages
  Stream<List<MessageModel>> listenToGroupMessages(String groupId) {
    return _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromMap(d.data())).toList());
  }

  // Listen to user groups
  // listenToUserGroups removed - use getUserGroups instead

  // Get user groups (alternative approach)
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection(AppConstants.colGroups)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) {
          final groups = snap.docs
              .map((d) => GroupModel.fromMap(d.data()))
              .where((g) => g.memberIds.contains(userId))
              .toList();
          return groups;
        });
  }

  // Listen to single group
  Stream<GroupModel> listenToGroup(String groupId) {
    return _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .snapshots()
        .map((doc) => GroupModel.fromMap(doc.data()!));
  }

  // Update group info
  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    await _firestore.collection(AppConstants.colGroups).doc(groupId).update(updates);
  }

  // Add admin
  Future<void> addAdmin(String groupId, String userId, AdminPermissions permissions) async {
    final doc = await _firestore.collection(AppConstants.colGroups).doc(groupId).get();
    final group = GroupModel.fromMap(doc.data()!);
    final updatedMembers = group.members.map((m) {
      if (m.userId == userId) {
        return GroupMember(
          userId: userId,
          role: 'admin',
          adminPermissions: permissions,
          joinedAt: m.joinedAt,
        );
      }
      return m;
    }).toList();

    await _firestore.collection(AppConstants.colGroups).doc(groupId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
  }

  // Remove admin
  Future<void> removeAdmin(String groupId, String userId) async {
    final doc = await _firestore.collection(AppConstants.colGroups).doc(groupId).get();
    final group = GroupModel.fromMap(doc.data()!);
    final updatedMembers = group.members.map((m) {
      if (m.userId == userId) {
        return GroupMember(userId: userId, role: 'member', joinedAt: m.joinedAt);
      }
      return m;
    }).toList();

    await _firestore.collection(AppConstants.colGroups).doc(groupId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
  }

  // Ban member
  Future<void> banMember(String groupId, String userId) async {
    final doc = await _firestore.collection(AppConstants.colGroups).doc(groupId).get();
    final group = GroupModel.fromMap(doc.data()!);
    final updatedMembers = group.members.map((m) {
      if (m.userId == userId) {
        return GroupMember(userId: userId, role: 'member', joinedAt: m.joinedAt, isBanned: true);
      }
      return m;
    }).toList();

    await _firestore.collection(AppConstants.colGroups).doc(groupId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });
  }

  // Leave group
  Future<void> leaveGroup(String groupId, String userId) async {
    final doc = await _firestore.collection(AppConstants.colGroups).doc(groupId).get();
    final group = GroupModel.fromMap(doc.data()!);
    final updatedMembers = group.members.where((m) => m.userId != userId).toList();

    await _firestore.collection(AppConstants.colGroups).doc(groupId).update({
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });

    await sendSystemMessage(groupId, 'غادر عضو المجموعة');
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    final messagesSnap = await _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(AppConstants.colGroups).doc(groupId));
    await batch.commit();
  }

  // Search groups
  Future<List<GroupModel>> searchGroups(String query) async {
    final results = <GroupModel>[];
    final lowerQuery = query.toLowerCase().replaceFirst('@', '');

    final usernameQuery = await _firestore
        .collection(AppConstants.colGroups)
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(10)
        .get();

    for (final doc in usernameQuery.docs) {
      results.add(GroupModel.fromMap(doc.data()));
    }

    final nameQuery = await _firestore
        .collection(AppConstants.colGroups)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    for (final doc in nameQuery.docs) {
      final group = GroupModel.fromMap(doc.data());
      if (!results.any((g) => g.id == group.id)) {
        results.add(group);
      }
    }

    return results;
  }

  // Add reaction to group message
  Future<void> addGroupReaction(String groupId, String messageId, String emoji, String userId) async {
    final msgRef = _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .doc(messageId);

    final doc = await msgRef.get();
    if (!doc.exists) return;

    final message = MessageModel.fromMap(doc.data()!);
    final reactions = Map<String, ReactionModel>.from(message.reactions);

    if (reactions.containsKey(emoji)) {
      final existing = reactions[emoji]!;
      if (existing.userIds.contains(userId)) {
        final newIds = existing.userIds.where((id) => id != userId).toList();
        if (newIds.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = ReactionModel(emoji: emoji, userIds: newIds);
        }
      } else {
        if (existing.userIds.length < 3) {
          reactions[emoji] = ReactionModel(emoji: emoji, userIds: [...existing.userIds, userId]);
        }
      }
    } else {
      reactions[emoji] = ReactionModel(emoji: emoji, userIds: [userId]);
    }

    final reactionsMap = <String, dynamic>{};
    reactions.forEach((key, val) => reactionsMap[key] = val.toMap());
    await msgRef.update({'reactions': reactionsMap});
  }

  // Delete group message
  Future<void> deleteGroupMessage(String groupId, String messageId) async {
    await _firestore
        .collection(AppConstants.colGroups)
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true, 'text': null, 'mediaUrl': null});
  }

  // Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    final doc = await _firestore.collection(AppConstants.colGroups).doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromMap(doc.data()!);
  }

}