import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../config/constants.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Generate chat ID between two users (sorted for consistency)
  String getChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Get or create chat
  Future<ChatModel> getOrCreateChat(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);
    final doc = await _firestore.collection(AppConstants.colChats).doc(chatId).get().timeout(const Duration(seconds: 12), onTimeout: () => throw Exception('timeout'));

    if (doc.exists) {
      return ChatModel.fromMap(doc.data()!);
    }

    final chat = ChatModel(
      id: chatId,
      participantIds: [userId1, userId2],
    );

    await _firestore.collection(AppConstants.colChats).doc(chatId).set(chat.toMap());
    return chat;
  }

  // Send message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String? senderName,
    required String? senderPhotoUrl,
    required MessageType type,
    String? text,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    int? duration,
    String? replyToId,
    String? replyToText,
    String? replyToSenderId,
    bool isForwarded = false,
    Map<String, dynamic>? extra,
  }) async {
    // Split long text into multiple messages
    if (type == MessageType.text && text != null && text.length > AppConstants.maxMessageLength) {
      final chunks = _splitText(text);
      MessageModel? lastMsg;
      for (final chunk in chunks) {
        lastMsg = await sendMessage(
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          senderPhotoUrl: senderPhotoUrl,
          type: type,
          text: chunk,
          replyToId: replyToId,
          replyToText: replyToText,
          replyToSenderId: replyToSenderId,
        );
      }
      return lastMsg!;
    }

    final msgId = _uuid.v4();
    final now = DateTime.now();

    final message = MessageModel(
      id: msgId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      isForwarded: isForwarded,
      createdAt: now,
      status: MessageStatus.sent,
      extra: extra,
    );

    await _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .doc(msgId)
        .set(message.toMap());

    // Update chat metadata
    String? displayText = _getDisplayText(type, text, fileName);
    await _firestore.collection(AppConstants.colChats).doc(chatId).update({
      'lastMessageText': displayText,
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastMessageType': type.name,
    });

    return message;
  }

  List<String> _splitText(String text) {
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      final end = (start + AppConstants.maxMessageLength).clamp(0, text.length);
      chunks.add(text.substring(start, end));
      start = end;
    }
    return chunks;
  }

  String? _getDisplayText(MessageType type, String? text, String? fileName) {
    switch (type) {
      case MessageType.text:
        return text;
      case MessageType.image:
        return 'صورة';
      case MessageType.video:
        return 'فيديو';
      case MessageType.file:
        return fileName ?? 'ملف';
      case MessageType.voice:
        return 'رسالة صوتية';
      case MessageType.sticker:
        return 'ملصق';
      case MessageType.emoji:
        return text;
      case MessageType.system:
        return text;
    }
  }

  // Listen to messages
  Stream<List<MessageModel>> listenToMessages(String chatId) {
    return _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data()))
            .toList());
  }

  // Load older messages
  Future<List<MessageModel>> loadOlderMessages(String chatId, DateTime before) async {
    final snap = await _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(30)
        .get().timeout(const Duration(seconds: 12), onTimeout: () => throw Exception('timeout'));

    return snap.docs.map((d) => MessageModel.fromMap(d.data())).toList();
  }

  // Edit message
  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
      'editedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId, {bool forEveryone = true}) async {
    if (forEveryone) {
      await _firestore
          .collection(AppConstants.colChats)
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'text': null,
        'mediaUrl': null,
      });
    } else {
      // Just hide locally - in a real app this would use a user-specific read list
      await _firestore
          .collection(AppConstants.colChats)
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    }
  }

  // Add reaction
  Future<void> addReaction(String chatId, String messageId, String emoji, String userId) async {
    final msgRef = _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await msgRef.get().timeout(const Duration(seconds: 12), onTimeout: () => throw Exception('timeout'));
    if (!doc.exists) return;

    final message = MessageModel.fromMap(doc.data()!);
    final reactions = Map<String, ReactionModel>.from(message.reactions);

    if (reactions.containsKey(emoji)) {
      final existing = reactions[emoji]!;
      if (existing.userIds.contains(userId)) {
        // Remove reaction
        final newIds = existing.userIds.where((id) => id != userId).toList();
        if (newIds.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = ReactionModel(emoji: emoji, userIds: newIds);
        }
      } else {
        // Add to existing
        reactions[emoji] = ReactionModel(emoji: emoji, userIds: [...existing.userIds, userId]);
      }
    } else {
      // New reaction
      reactions[emoji] = ReactionModel(emoji: emoji, userIds: [userId]);
    }

    final reactionsMap = <String, dynamic>{};
    reactions.forEach((key, val) => reactionsMap[key] = val.toMap());

    await msgRef.update({'reactions': reactionsMap});
  }

  // Pin message
  Future<void> pinMessage(String chatId, String messageId) async {
    await _firestore.collection(AppConstants.colChats).doc(chatId).update({
      'pinnedMessageId': messageId,
    });
    await _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': true});
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection(AppConstants.colChats).doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  // Get all chats for user
  Stream<List<ChatModel>> listenToChats(String userId) {
    return _firestore
        .collection(AppConstants.colChats)
        .where('participantIds', arrayContains: userId)
        .where('isAiChat', isEqualTo: false)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromMap(d.data())).toList());
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    final messagesSnap = await _firestore
        .collection(AppConstants.colChats)
        .doc(chatId)
        .collection('messages')
        .get().timeout(const Duration(seconds: 12), onTimeout: () => throw Exception('timeout'));

    final batch = _firestore.batch();
    for (final doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection(AppConstants.colChats).doc(chatId));
    await batch.commit();
  }

  // Forward message
  Future<void> forwardMessage({
    required MessageModel message,
    required String targetChatId,
    required String senderId,
    required String? senderName,
    required String? senderPhotoUrl,
  }) async {
    await sendMessage(
      chatId: targetChatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: message.type,
      text: message.text,
      mediaUrl: message.mediaUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      thumbnailUrl: message.thumbnailUrl,
      isForwarded: true,
    );
  }
}
