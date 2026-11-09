import '../../../features/discover/domain/photo_reference.dart';

class FeedPost {
  const FeedPost({
    required this.photo,
    required this.authorName,
    required this.username,
    required this.likeCount,
    required this.isLiked,
    this.avatarUrl,
  });

  final PhotoReference photo;
  final String authorName;
  final String username;
  final String? avatarUrl;
  final int likeCount;
  final bool isLiked;
}
