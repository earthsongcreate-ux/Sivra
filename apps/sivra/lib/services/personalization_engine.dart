import '../models/daily_pack.dart';
import '../models/learning_profile.dart';

class PersonalizationEngine {
  const PersonalizationEngine();

  LearningProfile buildProfile({
    required List<DailyPack> recentPacks,
    required List<String> focusAreas,
  }) {
    return LearningProfile.fromPacks(
      packs: recentPacks,
      focusAreas: focusAreas,
    );
  }
}
