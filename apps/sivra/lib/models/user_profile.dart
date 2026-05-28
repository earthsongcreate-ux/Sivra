class UserProfile {
  final String uid;
  final List<String> focusAreas;
  final List<String> thinkingRoles;
  final String? aiFluencyLevel;
  final String? onboardingObstacle;
  final String? routineTarget;
  final int onboardingVersion;

  const UserProfile({
    required this.uid,
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

    return UserProfile(
      uid: uid,
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
