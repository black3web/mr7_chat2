import 'package:cloud_firestore/cloud_firestore.dart';

class StickerModel {
  final String id;
  final String packId;
  final String userId;
  final String url;
  final bool isAnimated;
  final String? thumbnailUrl;
  final DateTime addedAt;

  StickerModel({
    required this.id,
    required this.packId,
    required this.userId,
    required this.url,
    this.isAnimated = false,
    this.thumbnailUrl,
    required this.addedAt,
  });

  factory StickerModel.fromMap(Map<String, dynamic> map) => StickerModel(
    id: map['id'] ?? '',
    packId: map['packId'] ?? '',
    userId: map['userId'] ?? '',
    url: map['url'] ?? '',
    isAnimated: map['isAnimated'] ?? false,
    thumbnailUrl: map['thumbnailUrl'],
    addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'packId': packId,
    'userId': userId,
    'url': url,
    'isAnimated': isAnimated,
    'thumbnailUrl': thumbnailUrl,
    'addedAt': Timestamp.fromDate(addedAt),
  };
}

class StickerPackModel {
  final String id;
  final String userId;
  final String name;
  final List<StickerModel> stickers;
  final DateTime createdAt;
  final bool isPersonal;

  StickerPackModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.stickers,
    required this.createdAt,
    this.isPersonal = true,
  });

  bool get isFull => stickers.length >= 250;
  int get count => stickers.length;

  factory StickerPackModel.fromMap(Map<String, dynamic> map) {
    final stickersRaw = map['stickers'] as List? ?? [];
    return StickerPackModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      stickers: stickersRaw.map((s) => StickerModel.fromMap(Map<String, dynamic>.from(s))).toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPersonal: map['isPersonal'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'stickers': stickers.map((s) => s.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'isPersonal': isPersonal,
  };
}
