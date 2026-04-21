import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPermissions {
  final bool deleteMessages;
  final bool banMembers;
  final bool inviteUsers;
  final bool pinMessages;
  final bool editGroupInfo;
  final bool addAdmins;
  final bool managePermissions;

  const AdminPermissions({
    this.deleteMessages = false,
    this.banMembers = false,
    this.inviteUsers = false,
    this.pinMessages = false,
    this.editGroupInfo = false,
    this.addAdmins = false,
    this.managePermissions = false,
  });

  factory AdminPermissions.all() => const AdminPermissions(
    deleteMessages: true,
    banMembers: true,
    inviteUsers: true,
    pinMessages: true,
    editGroupInfo: true,
    addAdmins: true,
    managePermissions: true,
  );

  factory AdminPermissions.fromMap(Map<String, dynamic> map) => AdminPermissions(
    deleteMessages: map['deleteMessages'] ?? false,
    banMembers: map['banMembers'] ?? false,
    inviteUsers: map['inviteUsers'] ?? false,
    pinMessages: map['pinMessages'] ?? false,
    editGroupInfo: map['editGroupInfo'] ?? false,
    addAdmins: map['addAdmins'] ?? false,
    managePermissions: map['managePermissions'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'deleteMessages': deleteMessages,
    'banMembers': banMembers,
    'inviteUsers': inviteUsers,
    'pinMessages': pinMessages,
    'editGroupInfo': editGroupInfo,
    'addAdmins': addAdmins,
    'managePermissions': managePermissions,
  };
}

class MemberPermissions {
  final bool sendMessages;
  final bool sendPhotos;
  final bool sendVideos;
  final bool sendFiles;
  final bool sendStickers;
  final bool pinMessages;

  const MemberPermissions({
    this.sendMessages = true,
    this.sendPhotos = true,
    this.sendVideos = true,
    this.sendFiles = true,
    this.sendStickers = true,
    this.pinMessages = false,
  });

  factory MemberPermissions.fromMap(Map<String, dynamic> map) => MemberPermissions(
    sendMessages: map['sendMessages'] ?? true,
    sendPhotos: map['sendPhotos'] ?? true,
    sendVideos: map['sendVideos'] ?? true,
    sendFiles: map['sendFiles'] ?? true,
    sendStickers: map['sendStickers'] ?? true,
    pinMessages: map['pinMessages'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'sendMessages': sendMessages,
    'sendPhotos': sendPhotos,
    'sendVideos': sendVideos,
    'sendFiles': sendFiles,
    'sendStickers': sendStickers,
    'pinMessages': pinMessages,
  };
}

class GroupMember {
  final String userId;
  final String role; // owner, admin, member
  final AdminPermissions? adminPermissions;
  final DateTime joinedAt;
  final bool isBanned;

  GroupMember({
    required this.userId,
    required this.role,
    this.adminPermissions,
    required this.joinedAt,
    this.isBanned = false,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';

  factory GroupMember.fromMap(Map<String, dynamic> map) => GroupMember(
    userId: map['userId'] ?? '',
    role: map['role'] ?? 'member',
    adminPermissions: map['adminPermissions'] != null
        ? AdminPermissions.fromMap(Map<String, dynamic>.from(map['adminPermissions']))
        : null,
    joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isBanned: map['isBanned'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'role': role,
    'adminPermissions': adminPermissions?.toMap(),
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isBanned': isBanned,
  };
}

class GroupModel {
  final String id;
  final String username; // unique @handle
  final String name;
  final String? photoUrl;
  final String? description;
  final String ownerId;
  final List<GroupMember> members;
  final MemberPermissions defaultPermissions;
  final DateTime createdAt;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final String? pinnedMessageId;
  final bool isPublic;

  GroupModel({
    required this.id,
    required this.username,
    required this.name,
    this.photoUrl,
    this.description,
    required this.ownerId,
    required this.members,
    MemberPermissions? defaultPermissions,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderId,
    Map<String, int>? unreadCounts,
    this.pinnedMessageId,
    this.isPublic = true,
  })  : defaultPermissions = defaultPermissions ?? const MemberPermissions(),
        unreadCounts = unreadCounts ?? {};

  List<String> get memberIds => members.map((m) => m.userId).toList();
  List<GroupMember> get admins => members.where((m) => m.isAdmin).toList();
  List<GroupMember> get regularMembers => members.where((m) => !m.isAdmin).toList();

  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  bool isAdmin(String userId) {
    final member = getMember(userId);
    return member?.isAdmin ?? false;
  }

  bool isOwner(String userId) => ownerId == userId;

  String get inviteLink => 'https://mr7chat.app/join/$username';

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    final membersRaw = map['members'] as List? ?? [];
    return GroupModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      description: map['description'],
      ownerId: map['ownerId'] ?? '',
      members: membersRaw
          .map((m) => GroupMember.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      defaultPermissions: map['defaultPermissions'] != null
          ? MemberPermissions.fromMap(Map<String, dynamic>.from(map['defaultPermissions']))
          : const MemberPermissions(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageText: map['lastMessageText'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      pinnedMessageId: map['pinnedMessageId'],
      isPublic: map['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'name': name,
    'photoUrl': photoUrl,
    'description': description,
    'ownerId': ownerId,
    'members': members.map((m) => m.toMap()).toList(),
    'defaultPermissions': defaultPermissions.toMap(),
    'createdAt': Timestamp.fromDate(createdAt),
    'lastMessageText': lastMessageText,
    'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'lastMessageSenderId': lastMessageSenderId,
    'unreadCounts': unreadCounts,
    'pinnedMessageId': pinnedMessageId,
    'isPublic': isPublic,
  };
}
