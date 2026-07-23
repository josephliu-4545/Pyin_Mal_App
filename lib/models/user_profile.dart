class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  /// Full-body photo the user saves once and reuses for every AI try-on.
  /// Stored as a public image URL (uploaded via ImageHostService), separate
  /// from [avatarUrl] so the profile picture and try-on photo stay independent.
  final String? tryOnPhotoUrl;
  final int points;
  final List<String> preferences;

  UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.tryOnPhotoUrl,
    this.points = 0,
    this.preferences = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      tryOnPhotoUrl: data['tryOnPhotoUrl'] as String?,
      points: data['points'] as int? ?? 0,
      preferences: List<String>.from(data['preferences'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'tryOnPhotoUrl': tryOnPhotoUrl,
      'points': points,
      'preferences': preferences,
    };
  }
}
