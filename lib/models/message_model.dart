import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, file, voice, sticker, emoji, system }
enum MessageStatus { sending, sent, delivered, read }

class ReactionModel {
  final String emoji;
  final List<String> userIds;

  ReactionModel({required this.emoji, required this.userIds});

  factory ReactionModel.fromMap(Map<String, dynamic> map) {
    return ReactionModel(
      emoji: map['emoji'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'emoji': emoji,
    'userIds': userIds,
  };
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final int? duration; // in seconds for audio/video
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderId;
  final bool isForwarded;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? editedAt;
  final MessageStatus status;
  final Map<String, ReactionModel> reactions; // emoji -> ReactionModel
  final Map<String, bool> readBy; // userId -> true
  final bool isPinned;
  final Map<String, dynamic>? extra; // for AI messages, sticker packs etc

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.duration,
    this.replyToId,
    this.replyToText,
    this.replyToSenderId,
    this.isForwarded = false,
    this.isEdited = false,
    this.isDeleted = false,
    required this.createdAt,
    this.editedAt,
    this.status = MessageStatus.sent,
    Map<String, ReactionModel>? reactions,
    Map<String, bool>? readBy,
    this.isPinned = false,
    this.extra,
  })  : reactions = reactions ?? {},
        readBy = readBy ?? {};

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final reactionsRaw = map['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = <String, ReactionModel>{};
    reactionsRaw.forEach((key, val) {
      reactions[key] = ReactionModel.fromMap(Map<String, dynamic>.from(val));
    });

    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'],
      senderPhotoUrl: map['senderPhotoUrl'],
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      thumbnailUrl: map['thumbnailUrl'],
      duration: map['duration'],
      replyToId: map['replyToId'],
      replyToText: map['replyToText'],
      replyToSenderId: map['replyToSenderId'],
      isForwarded: map['isForwarded'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      reactions: reactions,
      readBy: Map<String, bool>.from(map['readBy'] ?? {}),
      isPinned: map['isPinned'] ?? false,
      extra: map['extra'] != null ? Map<String, dynamic>.from(map['extra']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    final reactionsMap = <String, dynamic>{};
    reactions.forEach((key, val) {
      reactionsMap[key] = val.toMap();
    });

    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSenderId': replyToSenderId,
      'isForwarded': isForwarded,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'status': status.name,
      'reactions': reactionsMap,
      'readBy': readBy,
      'isPinned': isPinned,
      'extra': extra,
    };
  }

  bool get isEmojiOnly {
    if (type != MessageType.text || text == null) return false;
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|\s)+$',
    );
    return emojiRegex.hasMatch(text!);
  }

  int get emojiCount {
    if (!isEmojiOnly || text == null) return 0;
    return text!.trim().split('').where((c) => c.trim().isNotEmpty).length;
  }

  MessageModel copyWith({
    String? text,
    bool? isEdited,
    bool? isDeleted,
    DateTime? editedAt,
    MessageStatus? status,
    Map<String, ReactionModel>? reactions,
    Map<String, bool>? readBy,
    bool? isPinned,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      text: text ?? this.text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      isForwarded: isForwarded,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      isPinned: isPinned ?? this.isPinned,
      extra: extra,
    );
  }
}

class ChatModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final MessageType? lastMessageType;
  final Map<String, int> unreadCounts; // userId -> count
  final Map<String, bool> muted;
  final String? pinnedMessageId;
  final bool isAiChat;
  final String? aiType; // gemini, deepseek, image, video
  final Map<String, dynamic>? aiMeta;

  ChatModel({
    required this.id,
    required this.participantIds,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.lastMessageType,
    Map<String, int>? unreadCounts,
    Map<String, bool>? muted,
    this.pinnedMessageId,
    this.isAiChat = false,
    this.aiType,
    this.aiMeta,
  })  : unreadCounts = unreadCounts ?? {},
        muted = muted ?? {};

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessageText: map['lastMessageText'],
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageType: map['lastMessageType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == map['lastMessageType'],
              orElse: () => MessageType.text,
            )
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      muted: Map<String, bool>.from(map['muted'] ?? {}),
      pinnedMessageId: map['pinnedMessageId'],
      isAiChat: map['isAiChat'] ?? false,
      aiType: map['aiType'],
      aiMeta: map['aiMeta'] != null ? Map<String, dynamic>.from(map['aiMeta']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'participantIds': participantIds,
    'lastMessageText': lastMessageText,
    'lastMessageSenderId': lastMessageSenderId,
    'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'lastMessageType': lastMessageType?.name,
    'unreadCounts': unreadCounts,
    'muted': muted,
    'pinnedMessageId': pinnedMessageId,
    'isAiChat': isAiChat,
    'aiType': aiType,
    'aiMeta': aiMeta,
  };
}
