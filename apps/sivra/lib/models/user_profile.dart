class UserProfile {
  final String uid;
  final String? firstName;
  final List<String> focusAreas;
  final List<String> thinkingRoles;
  final String? aiFluencyLevel;
  final String? onboardingObstacle;
  final String? routineTarget;
  final int onboardingVersion;

  const UserProfile({
    required this.uid,
    this.firstName,
    required this.focusAreas,
    this.thinkingRoles = const <String>[],
    this.aiFluencyLevel,
    this.onboardingObstacle,
    this.routineTarget,
    this.onboardingVersion = 1,
  });

  factory UserProfile.fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final raw = data['focusAreas'];
    final focusAreas = raw is List
        ? raw.whereType<String>().toList()
        : <String>[];
    final onboarding = data['onboarding'];
    final onboardingMap = onboarding is Map<String, dynamic>
        ? onboarding
        : const <String, dynamic>{};
    final rawFirstName = data['firstName'];
    final rawDisplayName = data['displayName'];
    final displayName = rawDisplayName is String ? rawDisplayName.trim() : '';
    final firstName = rawFirstName is String && rawFirstName.trim().isNotEmpty
        ? rawFirstName.trim()
        : displayName.isNotEmpty
        ? displayName.split(RegExp(r'\s+')).first
        : null;

    return UserProfile(
      uid: uid,
      firstName: firstName,
      focusAreas: focusAreas,
      thinkingRoles: onboardingMap['thinkingRoles'] is List
          ? (onboardingMap['thinkingRoles'] as List)
                .whereType<String>()
                .toList()
          : const <String>[],
      aiFluencyLevel: onboardingMap['aiFluencyLevel'] is String
          ? onboardingMap['aiFluencyLevel'] as String
          : null,
      onboardingObstacle: onboardingMap['obstacle'] is String
          ? onboardingMap['obstacle'] as String
          : null,
      routineTarget: onboardingMap['routineTarget'] is String
          ? onboardingMap['routineTarget'] as String
          : null,
      onboardingVersion: onboardingMap['version'] is int
          ? onboardingMap['version'] as int
          : 1,
    );
  }
}
