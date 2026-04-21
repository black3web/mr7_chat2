import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;         // 15-digit unique ID
  final String username;   // unique @handle
  final String name;
  final String passwordHash;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isBanned;
  final bool isAdmin;      // app admin (developer)
  final Map<String, dynamic> privacy;
  final Map<String, dynamic> settings;
  final List<String> contacts; // list of user IDs
  final List<String> blocked;
  final Map<String, String> contactNicknames; // userId -> nickname
  final String? bio;
  final int storiesCount;
  final Map<String, dynamic>? storySettings;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.passwordHash,
    this.photoUrl,
    required this.createdAt,
    this.lastSeen,
    this.isOnline = false,
    this.isBanned = false,
    this.isAdmin = false,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? settings,
    List<String>? contacts,
    List<String>? blocked,
    Map<String, String>? contactNicknames,
    this.bio,
    this.storiesCount = 0,
    this.storySettings,
  })  : privacy = privacy ?? _defaultPrivacy(),
        settings = settings ?? _defaultSettings(),
        contacts = contacts ?? [],
        blocked = blocked ?? [],
        contactNicknames = contactNicknames ?? {};

  static Map<String, dynamic> _defaultPrivacy() => {
    'hideLastSeen': false,
    'hideOnlineStatus': false,
    'hideName': false,
    'hideProfilePhoto': false,
    'whoCanSeeStories': 'contacts', // everyone, contacts, nobody
  };

  static Map<String, dynamic> _defaultSettings() => {
    'language': 'ar',
    'theme': 'dark',
    'notifications': true,
    'messagePreview': true,
    'soundEnabled': true,
    'vibrationEnabled': true,
    'autoDownload': true,
    'chatBackground': null,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      isOnline: map['isOnline'] ?? false,
      isBanned: map['isBanned'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      privacy: Map<String, dynamic>.from(map['privacy'] ?? _defaultPrivacy()),
      settings: Map<String, dynamic>.from(map['settings'] ?? _defaultSettings()),
      contacts: List<String>.from(map['contacts'] ?? []),
      blocked: List<String>.from(map['blocked'] ?? []),
      contactNicknames: Map<String, String>.from(map['contactNicknames'] ?? {}),
      bio: map['bio'],
      storiesCount: map['storiesCount'] ?? 0,
      storySettings: map['storySettings'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'name': name,
    'passwordHash': passwordHash,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    'isOnline': isOnline,
    'isBanned': isBanned,
    'isAdmin': isAdmin,
    'privacy': privacy,
    'settings': settings,
    'contacts': contacts,
    'blocked': blocked,
    'contactNicknames': contactNicknames,
    'bio': bio,
    'storiesCount': storiesCount,
    'storySettings': storySettings,
  };

  UserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? passwordHash,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isBanned,
    bool? isAdmin,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? settings,
    List<String>? contacts,
    List<String>? blocked,
    Map<String, String>? contactNicknames,
    String? bio,
    int? storiesCount,
    Map<String, dynamic>? storySettings,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isBanned: isBanned ?? this.isBanned,
      isAdmin: isAdmin ?? this.isAdmin,
      privacy: privacy ?? this.privacy,
      settings: settings ?? this.settings,
      contacts: contacts ?? this.contacts,
      blocked: blocked ?? this.blocked,
      contactNicknames: contactNicknames ?? this.contactNicknames,
      bio: bio ?? this.bio,
      storiesCount: storiesCount ?? this.storiesCount,
      storySettings: storySettings ?? this.storySettings,
    );
  }

  String getDisplayName(String viewerId, Map<String, String> contactNicknames) {
    if (contactNicknames.containsKey(id)) {
      return contactNicknames[id]!;
    }
    return name;
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  int get avatarColorIndex => id.hashCode.abs() % 12;
}
