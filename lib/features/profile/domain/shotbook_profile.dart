class ShotbookProfile {
  const ShotbookProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;

  factory ShotbookProfile.fromJson(Map<String, dynamic> json) =>
      ShotbookProfile(
        id: json['id'] as String,
        username: json['username'] as String? ?? 'member',
        displayName: json['display_name'] as String? ?? 'SHOTBOOK member',
        bio: json['bio'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
      );
}

class ProfilePreset {
  const ProfilePreset({
    required this.name,
    required this.photoCount,
    required this.settings,
  });

  final String name;
  final int photoCount;
  final Map<String, String> settings;
}
