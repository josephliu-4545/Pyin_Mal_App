import 'package:cloud_firestore/cloud_firestore.dart';

/// A single "outfit of the day" post in the community feed. [wardrobeItemIds]
/// is what links a real photo to specific tagged wardrobe items — the actual
/// data hook behind this feature.
class OutfitPost {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String imageUrl;
  final String? caption;
  final List<String> wardrobeItemIds;
  final int likeCount;
  final DateTime createdAt;

  const OutfitPost({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.imageUrl,
    this.caption,
    this.wardrobeItemIds = const [],
    this.likeCount = 0,
    required this.createdAt,
  });

  factory OutfitPost.fromMap(Map<String, dynamic> data, String id) {
    return OutfitPost(
      id: id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? 'Anonymous',
      avatarUrl: data['avatarUrl'] as String?,
      imageUrl: data['imageUrl'] as String? ?? '',
      caption: data['caption'] as String?,
      wardrobeItemIds: List<String>.from(data['wardrobeItemIds'] ?? const []),
      likeCount: data['likeCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'imageUrl': imageUrl,
      'caption': caption,
      'wardrobeItemIds': wardrobeItemIds,
      'likeCount': likeCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
