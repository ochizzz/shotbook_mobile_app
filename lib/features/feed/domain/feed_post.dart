import '../../../features/discover/domain/photo_reference.dart';

class FeedPost {
  const FeedPost({
    required this.photo,
    required this.authorName,
    required this.username,
    this.avatarUrl,
  });

  final PhotoReference photo;
  final String authorName;
  final String username;
  final String? avatarUrl;

  /// Popularity is shown as views, not likes.
  int get viewCount => photo.viewCount;
}
