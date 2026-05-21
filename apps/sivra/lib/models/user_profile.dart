class UserProfile {
  final String uid;
  final List<String> focusAreas;

  const UserProfile({
    required this.uid,
    required this.focusAreas,
  });

  factory UserProfile.fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final raw = data['focusAreas'];
    final focusAreas = raw is List ? raw.whereType<String>().toList() : <String>[];

    return UserProfile(
      uid: uid,
      focusAreas: focusAreas,
    );
  }
}

