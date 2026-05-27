class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final int points;
  final List<String> preferences;

  UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.points = 0,
    this.preferences = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      points: data['points'] as int? ?? 0,
      preferences: List<String>.from(data['preferences'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'points': points,
      'preferences': preferences,
    };
  }
}
