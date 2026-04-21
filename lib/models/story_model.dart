import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryMediaType { image, video }

class StoryView {
  final String userId;
  final DateTime viewedAt;
  final String? reaction;

  StoryView({required this.userId, required this.viewedAt, this.reaction});

  factory StoryView.fromMap(Map<String, dynamic> map) => StoryView(
    userId: map['userId'] ?? '',
    viewedAt: (map['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    reaction: map['reaction'],
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'viewedAt': Timestamp.fromDate(viewedAt),
    'reaction': reaction,
  };
}

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final StoryMediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<StoryView> views;
  final bool isDeleted;
  final List<String> taggedUsers;
  final String? link;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.description,
    required this.createdAt,
    required this.expiresAt,
    List<StoryView>? views,
    this.isDeleted = false,
    List<String>? taggedUsers,
    this.link,
  })  : views = views ?? [],
        taggedUsers = taggedUsers ?? [];

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == StoryMediaType.video;
  int get viewCount => views.length;

  bool hasViewed(String userId) => views.any((v) => v.userId == userId);

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final viewsRaw = map['views'] as List? ?? [];
    return StoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      mediaType: map['mediaType'] == 'video' ? StoryMediaType.video : StoryMediaType.image,
      mediaUrl: map['mediaUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 48)),
      views: viewsRaw.map((v) => StoryView.fromMap(Map<String, dynamic>.from(v))).toList(),
      isDeleted: map['isDeleted'] ?? false,
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      link: map['link'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'mediaType': mediaType.name,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'views': views.map((v) => v.toMap()).toList(),
    'isDeleted': isDeleted,
    'taggedUsers': taggedUsers,
    'link': link,
  };
}

class UserStoriesGroup {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final List<StoryModel> stories;

  UserStoriesGroup({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.stories,
  });

  bool hasUnseenStories(String viewerId) {
    return stories.any((s) => !s.hasViewed(viewerId) && !s.isExpired && !s.isDeleted);
  }

  int get unseenCount {
    return stories.where((s) => !s.isDeleted && !s.isExpired).length;
  }

  List<StoryModel> get activeStories {
    return stories.where((s) => !s.isDeleted && !s.isExpired).toList();
  }
}
