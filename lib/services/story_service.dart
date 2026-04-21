import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/story_model.dart';
import '../config/constants.dart';

class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Check stories limit
  Future<bool> canAddStory(String userId) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: AppConstants.storyDurationHours));
    final query = await _firestore
        .collection(AppConstants.colStories)
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .where('isDeleted', isEqualTo: false)
        .get();
    return query.docs.length < AppConstants.maxStoriesPerCycle;
  }

  // Add story
  Future<StoryModel> createStory({String? mediaType, String? description, required String userId, required String userName, String? userPhotoUrl, required String mediaUrl}) async => addStory(userId: userId, userName: userName, userPhotoUrl: userPhotoUrl, mediaUrl: mediaUrl, mediaType: mediaType == "video" ? StoryMediaType.video : StoryMediaType.image, description: description);

  Future<StoryModel> addStory({
    required String userId,
    required String userName,
    required String? userPhotoUrl,
    required StoryMediaType mediaType,
    required String mediaUrl,
    String? thumbnailUrl,
    String? description,
    List<String>? taggedUsers,
    String? link,
  }) async {
    if (!await canAddStory(userId)) {
      throw Exception('لقد وصلت للحد الأقصى من القصص');
    }

    final storyId = _uuid.v4();
    final now = DateTime.now();
    final story = StoryModel(
      id: storyId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      description: description,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: AppConstants.storyDurationHours)),
      taggedUsers: taggedUsers,
      link: link,
    );

    await _firestore.collection(AppConstants.colStories).doc(storyId).set(story.toMap());
    return story;
  }

  // Delete story
  Future<void> deleteStory(String storyId) async {
    await _firestore.collection(AppConstants.colStories).doc(storyId).update({
      'isDeleted': true,
    });
  }

  // Update story description
  Future<void> updateStoryDescription(String storyId, String description) async {
    await _firestore.collection(AppConstants.colStories).doc(storyId).update({
      'description': description,
    });
  }

  // View story
  Future<void> viewStory(String storyId, String viewerId) async {
    final storyRef = _firestore.collection(AppConstants.colStories).doc(storyId);
    final doc = await storyRef.get();
    if (!doc.exists) return;

    final story = StoryModel.fromMap(doc.data()!);
    if (story.hasViewed(viewerId)) return;

    final newView = StoryView(userId: viewerId, viewedAt: DateTime.now());
    await storyRef.update({
      'views': FieldValue.arrayUnion([newView.toMap()]),
    });
  }

  // React to story
  Future<void> reactToStory(String storyId, String viewerId, String reaction) async {
    final storyRef = _firestore.collection(AppConstants.colStories).doc(storyId);
    final doc = await storyRef.get();
    if (!doc.exists) return;

    final story = StoryModel.fromMap(doc.data()!);
    final views = story.views.map((v) {
      if (v.userId == viewerId) {
        return StoryView(userId: viewerId, viewedAt: v.viewedAt, reaction: reaction);
      }
      return v;
    }).toList();

    await storyRef.update({
      'views': views.map((v) => v.toMap()).toList(),
    });
  }

  // Get stories for user feed (contacts' stories)
  Stream<List<UserStoriesGroup>> getFeedStories(String userId, List<String> contactIds) {
    final allUserIds = [...contactIds, userId];
    final cutoff = DateTime.now().subtract(const Duration(hours: AppConstants.storyDurationHours));

    return _firestore
        .collection(AppConstants.colStories)
        .where('userId', whereIn: allUserIds.isEmpty ? ['__null__'] : allUserIds.take(10).toList())
        .where('isDeleted', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) {
          final stories = snap.docs.map((d) => StoryModel.fromMap(d.data())).toList();
          final groups = <String, List<StoryModel>>{};
          for (final story in stories) {
            if (!groups.containsKey(story.userId)) {
              groups[story.userId] = [];
            }
            groups[story.userId]!.add(story);
          }

          final result = groups.entries.map((entry) {
            final userStories = entry.value;
            userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final first = userStories.first;
            return UserStoriesGroup(
              userId: entry.key,
              userName: first.userName,
              userPhotoUrl: first.userPhotoUrl,
              stories: userStories,
            );
          }).toList();

          // Sort: own stories first, then unseen, then seen
          result.sort((a, b) {
            if (a.userId == userId) return -1;
            if (b.userId == userId) return 1;
            final aUnseen = a.hasUnseenStories(userId);
            final bUnseen = b.hasUnseenStories(userId);
            if (aUnseen && !bUnseen) return -1;
            if (!aUnseen && bUnseen) return 1;
            return 0;
          });

          return result;
        });
  }

  // Get user's own stories
  Stream<List<StoryModel>> getUserStories(String userId) {
    final cutoff = DateTime.now().subtract(const Duration(hours: AppConstants.storyDurationHours));
    return _firestore
        .collection(AppConstants.colStories)
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StoryModel.fromMap(d.data())).toList());
  }

  // Get story viewers
  Future<List<StoryView>> getStoryViewers(String storyId) async {
    final doc = await _firestore.collection(AppConstants.colStories).doc(storyId).get();
    if (!doc.exists) return [];
    final story = StoryModel.fromMap(doc.data()!);
    return story.views;
  }
}
